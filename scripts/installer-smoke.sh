#!/usr/bin/env bash
# Smoke matrix for install.sh — the SAME runs execute locally and in CI (installer-smoke.yml).
# Isolation: CLAUDE_HOME redirects the file copies to a throwaway dir, and a PATH shim hides
# the `claude` CLI (it would otherwise touch the real ~/.claude.json and plugin state).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# Explicit template: macOS mktemp ignores TMPDIR without one (uses confstr temp dir).
T="$(mktemp -d "${TMPDIR:-/tmp}/claude-smoke.XXXXXX")"
trap 'rm -rf "$T"' EXIT

fail() { echo "SMOKE FAIL: $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required for the smoke matrix"
mkdir -p "$T/bin"
ln -s "$(command -v jq)" "$T/bin/jq"
py_bin="$(command -v python3 || command -v python || true)"
if [ -n "$py_bin" ]; then ln -s "$py_bin" "$T/bin/python3"; fi
SAFE_PATH="$T/bin:/usr/bin:/bin"

export CLAUDE_HOME="$T/home"

echo "== run 1: fresh install (no backup expected, manifest written) =="
PATH="$SAFE_PATH" bash "$REPO/install.sh"
[ -f "$CLAUDE_HOME/.install-manifest" ] || fail "manifest not created"
if find "$CLAUDE_HOME" -maxdepth 1 -name '.backup-*' -type d | grep -q .; then
  fail "backup created on a fresh install"
fi

echo "== run 2: CLAUDE_LANGUAGE=english (backup + rewrite + persistence file) =="
PATH="$SAFE_PATH" CLAUDE_LANGUAGE=english bash "$REPO/install.sh"
find "$CLAUDE_HOME" -maxdepth 1 -name '.backup-*' -type d | grep -q . || fail "no backup on overwrite run"
grep -qF '"language": "english"' "$CLAUDE_HOME/settings.json" || fail "settings.json language not set"
grep -qF 'Always answer **in English**' "$CLAUDE_HOME/CLAUDE.md" || fail "CLAUDE.md not rewritten"
grep -qF 'CLAUDE_LANGUAGE=english' "$CLAUDE_HOME/.install-profile" || fail "language not persisted"

echo "== run 3: no variable — persisted language must hold =="
PATH="$SAFE_PATH" bash "$REPO/install.sh"
grep -qF '"language": "english"' "$CLAUDE_HOME/settings.json" || fail "persisted language lost on re-run"

echo "== run 4: orphan (manifest-listed) pruned, user file (unlisted) survives =="
echo 'skills/obsolete/SKILL.md' >> "$CLAUDE_HOME/.install-manifest"
mkdir -p "$CLAUDE_HOME/skills/obsolete"
echo x > "$CLAUDE_HOME/skills/obsolete/SKILL.md"
echo keep > "$CLAUDE_HOME/skills/my-own-note.md"
PATH="$SAFE_PATH" bash "$REPO/install.sh"
[ ! -e "$CLAUDE_HOME/skills/obsolete/SKILL.md" ] || fail "orphan not pruned"
[ ! -d "$CLAUDE_HOME/skills/obsolete" ] || fail "empty orphan dir not removed"
[ -f "$CLAUDE_HOME/skills/my-own-note.md" ] || fail "user file was deleted"

echo "== run 5: backups capped at 3, copies faithful, edited JSON still valid =="
PATH="$SAFE_PATH" bash "$REPO/install.sh"
backups="$(find "$CLAUDE_HOME" -maxdepth 1 -name '.backup-*' -type d | wc -l | tr -d ' ')"
[ "$backups" -le 3 ] || fail "more than 3 backups kept ($backups)"
[ "$backups" -ge 1 ] || fail "expected at least one backup"
diff -r "$CLAUDE_HOME/skills/setup-project" "$REPO/global/skills/setup-project" >/dev/null \
  || fail "installed skills differ from the repo sources"
jq empty "$CLAUDE_HOME/settings.json" || fail "settings.json no longer valid JSON"

echo "== run 6: --dry-run previews and writes nothing =="
before_settings="$(cat "$CLAUDE_HOME/settings.json")"
before_manifest="$(cat "$CLAUDE_HOME/.install-manifest")"
before_backups="$(find "$CLAUDE_HOME" -maxdepth 1 -name '.backup-*' -type d | wc -l | tr -d ' ')"
PATH="$SAFE_PATH" bash "$REPO/install.sh" --dry-run > "$T/dryrun.log" 2>&1 || fail "--dry-run exited non-zero"
grep -q 'DRY-RUN' "$T/dryrun.log" || fail "--dry-run banner missing"
[ "$before_settings" = "$(cat "$CLAUDE_HOME/settings.json")" ] || fail "--dry-run modified settings.json"
[ "$before_manifest" = "$(cat "$CLAUDE_HOME/.install-manifest")" ] || fail "--dry-run modified the manifest"
after_backups="$(find "$CLAUDE_HOME" -maxdepth 1 -name '.backup-*' -type d | wc -l | tr -d ' ')"
[ "$before_backups" = "$after_backups" ] || fail "--dry-run created a backup"
if PATH="$SAFE_PATH" bash "$REPO/install.sh" --nope >/dev/null 2>&1; then
  fail "unknown option accepted"
fi

echo "== run 7: FAILURE PATH — anchor mutated in the SOURCE kit =="
# The real-world failure vector is a reworded source file (a mutated installed copy is
# simply overwritten by the next run), so the guard is exercised on a temp kit copy.
KIT="$T/kit"
mkdir -p "$KIT"
cp -R "$REPO/install.sh" "$REPO/global" "$REPO/scripts" "$KIT/"
kit_md="$(cat "$KIT/global/CLAUDE.md")"
printf '%s\n' "${kit_md/Always answer/ALWAYS answer}" > "$KIT/global/CLAUDE.md"
export CLAUDE_HOME="$T/home2"
if ! PATH="$SAFE_PATH" CLAUDE_LANGUAGE=english bash "$KIT/install.sh" > "$T/run6.log" 2>&1; then
  cat "$T/run6.log"
  fail "installer aborted instead of degrading on a missing anchor"
fi
grep -q 'WARNING: language anchor not found in CLAUDE.md' "$T/run6.log" \
  || { cat "$T/run6.log"; fail "missing-anchor WARNING not emitted"; }
grep -qF '"language": "english"' "$CLAUDE_HOME/settings.json" \
  || fail "settings.json skipped (the jq path must not depend on the anchor)"
# 'in English' alone would false-positive: the source file legitimately contains it
# ("Research and doc lookups: always in English"); match the rewritten anchor context.
if grep -qF 'answer **in English**' "$CLAUDE_HOME/CLAUDE.md"; then
  fail "partial rewrite happened despite missing anchor"
fi
grep -qF 'ALWAYS answer' "$CLAUDE_HOME/CLAUDE.md" || fail "installed copy does not match the mutated source"

echo "SMOKE OK: all 7 runs passed"
