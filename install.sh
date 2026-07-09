#!/usr/bin/env bash
# Restores the Claude Code global configuration from this directory.
# Safe to re-run: it overwrites ~/.claude config files with the versions here.
# OWNER-ONLY: this replaces ~/.claude (CLAUDE.md, settings, hooks, statusline) with the
# owner's personal setup. To configure a single project or use only the plugins, do NOT
# run this — see AGENT-PROJECT-SETUP.md instead.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"

echo "Restoring Claude Code config: $SRC -> $DEST"
echo "  (owner-only: overwrites the global config; project setup lives in AGENT-PROJECT-SETUP.md)"
mkdir -p "$DEST"

# --- Backup what this run will replace (last 3 backups kept) -------------------
ts="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEST/.backup-$ts"
for item in CLAUDE.md settings.json statusline.sh skills agents hooks rules; do
  if [ -e "$DEST/$item" ]; then
    mkdir -p "$BACKUP"
    cp -R "$DEST/$item" "$BACKUP/$item"
  fi
done
if [ -d "$BACKUP" ]; then
  echo "  backup: $BACKUP (rollback: copy its contents back into $DEST)"
fi
find "$DEST" -maxdepth 1 -name '.backup-*' -type d | LC_ALL=C sort -r | tail -n +4 \
  | while IFS= read -r old_backup; do rm -rf "$old_backup"; done

cp "$SRC/global/CLAUDE.md" "$DEST/CLAUDE.md"
cp "$SRC/global/settings.json" "$DEST/settings.json"
cp -R "$SRC/global/skills" "$DEST/"
cp -R "$SRC/global/agents" "$DEST/"
cp -R "$SRC/global/hooks" "$DEST/"
cp -R "$SRC/global/rules" "$DEST/"
cp "$SRC/global/statusline.sh" "$DEST/statusline.sh"
chmod +x "$DEST/hooks/"*.sh "$DEST/statusline.sh"
find "$DEST/skills" "$DEST/agents" "$DEST/hooks" "$DEST/rules" -name ".DS_Store" -delete 2>/dev/null || true

# --- Orphan pruning (manifest-listed paths ONLY — never unknown user files) ----
# The manifest records exactly what the copy block above ships; files listed in a
# previous manifest but no longer shipped are removed, so renamed/deleted skills
# or rules stop loading into every session instead of lingering forever.
MANIFEST="$DEST/.install-manifest"
new_manifest="$( (cd "$SRC/global" && find CLAUDE.md settings.json statusline.sh skills agents hooks rules -type f ! -name '.DS_Store') | LC_ALL=C sort )"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r rel; do
    if [ -z "$rel" ]; then continue; fi
    case "$rel" in /*|*..*) continue ;; esac  # defensive: relative paths only, no traversal
    if ! printf '%s\n' "$new_manifest" | grep -Fxq "$rel"; then
      rm -f "$DEST/$rel"
      echo "  pruned (no longer shipped): $rel"
    fi
  done < "$MANIFEST"
  find "$DEST/skills" "$DEST/agents" "$DEST/hooks" "$DEST/rules" -type d -empty -delete 2>/dev/null || true
fi
printf '%s\n' "$new_manifest" > "$MANIFEST"

command -v jq >/dev/null 2>&1 \
  || echo "  WARNING: jq not found — statusline will be minimal. Install: brew install jq (macOS) / winget install jqlang.jq (Windows) / sudo apt install jq (Linux)."

# Any Python works for the JSON merges below; python3 is not a given on Windows/Git Bash.
PY="$(command -v python3 || command -v python || command -v py || true)"

# --- Response language (CLAUDE_LANGUAGE, persisted machine-locally) ------------
# Applies to the COPIES in $DEST only; the repo sources stay Spanish-default. The
# anchor literals live in scripts/language-anchors.env (single source, asserted
# by CI via scripts/check-language-anchors.sh).
INSTALL_PROFILE="$DEST/.install-profile"
lang="${CLAUDE_LANGUAGE:-}"
if [ -z "$lang" ] && [ -f "$INSTALL_PROFILE" ]; then
  lang="$(sed -n 's/^CLAUDE_LANGUAGE=//p' "$INSTALL_PROFILE" | tail -n 1)"
fi
lang="$(printf '%s' "$lang" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
case "$lang" in
  *[!a-z-]*)
    echo "  WARNING: invalid CLAUDE_LANGUAGE '$lang' (letters/hyphens only) — keeping Spanish."
    lang=""
    ;;
esac
if [ -n "$lang" ]; then
  printf 'CLAUDE_LANGUAGE=%s\n' "$lang" > "$INSTALL_PROFILE"
fi
if [ -n "$lang" ] && [ "$lang" != "spanish" ]; then
  if [ -f "$SRC/scripts/language-anchors.env" ]; then
    # shellcheck disable=SC1091
    . "$SRC/scripts/language-anchors.env"
  fi
  lang_cap="$(printf '%s' "$lang" | cut -c1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$lang" | cut -c2-)"
  if command -v jq >/dev/null 2>&1; then
    jq --arg l "$lang" '.language = $l' "$DEST/settings.json" > "$DEST/settings.json.tmp" \
      && mv "$DEST/settings.json.tmp" "$DEST/settings.json"
  elif [ -n "$PY" ]; then
    CLAUDE_LANG_VALUE="$lang" "$PY" -c "
import json, os
p = '$DEST/settings.json'
d = json.load(open(p))
d['language'] = os.environ['CLAUDE_LANG_VALUE']
open(p, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')"
  else
    echo "  WARNING: neither jq nor python found — set \"language\": \"$lang\" in $DEST/settings.json manually."
  fi
  if [ -n "${CLAUDE_MD_LANGUAGE_ANCHOR:-}" ] && grep -qF "$CLAUDE_MD_LANGUAGE_ANCHOR" "$DEST/CLAUDE.md"; then
    md_content="$(cat "$DEST/CLAUDE.md")"
    md_replacement="${CLAUDE_MD_LANGUAGE_ANCHOR/Spanish/$lang_cap}"
    printf '%s\n' "${md_content/"$CLAUDE_MD_LANGUAGE_ANCHOR"/"$md_replacement"}" > "$DEST/CLAUDE.md"
    echo "  language: $lang (persisted in .install-profile; plain re-runs keep it)"
  else
    echo "  WARNING: language anchor not found in CLAUDE.md — edit its Language section manually."
  fi
fi

# --- Secrets -------------------------------------------------------------------
# secrets.env is sourced here and injected directly into the MCP registration
# below (~/.claude.json, machine-local, never committed). Note: a user-level
# settings.local.json is NOT read by Claude Code (only project-level is) — never
# rely on an env block there.
if [ -f "$SRC/secrets.env" ]; then
  # shellcheck disable=SC1091
  source "$SRC/secrets.env"
else
  echo "  WARNING: secrets.env not found — context7 will be registered keyless (lower rate limits)."
  echo "           Copy secrets.env.example to secrets.env and re-run to add the key."
fi

# --- MCP servers (user scope) + plugins --------------------------------------
if command -v claude >/dev/null 2>&1; then
  key="${CONTEXT7_API_KEY:-}"
  if command -v jq >/dev/null 2>&1; then
    ctx7_json="$(jq -c --arg k "$key" \
      '.mcpServers.context7 | if $k != "" then .env.CONTEXT7_API_KEY = $k else del(.env) end' \
      "$SRC/global/mcp-servers.json")"
  elif [ -n "$PY" ]; then
    ctx7_json="$(CTX7_KEY="$key" "$PY" -c "
import json, os
d = json.load(open('$SRC/global/mcp-servers.json'))['mcpServers']['context7']
k = os.environ.get('CTX7_KEY', '')
if k:
    d.setdefault('env', {})['CONTEXT7_API_KEY'] = k
else:
    d.pop('env', None)
print(json.dumps(d))")"
  else
    ctx7_json=""
    echo "  WARNING: neither jq nor python found — register context7 manually: claude mcp add-json context7 '<json from global/mcp-servers.json, with your real key in env>' --scope user"
  fi
  if [ -n "$ctx7_json" ]; then
    # Remove-then-add so config/key updates take effect (add-json fails if it exists).
    claude mcp remove context7 --scope user >/dev/null 2>&1 || true
    if claude mcp add-json context7 "$ctx7_json" --scope user 2>/dev/null; then
      if [ -n "$key" ]; then
        echo "  MCP: context7 registered (user scope, with API key)"
      else
        echo "  MCP: context7 registered (user scope, keyless — lower rate limits)"
      fi
    else
      echo "  MCP: context7 registration failed — check with 'claude mcp list'"
    fi
  fi

  # Personal marketplace (this repo) — register or refresh, idempotent.
  # shellcheck disable=SC2015  # echo as the && branch cannot fail
  claude plugin marketplace add "$SRC" 2>/dev/null \
    && echo "  marketplace: gaston-plugins registered" \
    || { claude plugin marketplace update gaston-plugins 2>/dev/null \
         && echo "  marketplace: gaston-plugins refreshed" \
         || echo "  marketplace: could not register — check 'claude plugin marketplace list'"; }

  while IFS= read -r plugin; do
    case "$plugin" in ''|\#*) continue ;; esac
    claude plugin install "$plugin" 2>/dev/null \
      && echo "  plugin installed: $plugin" \
      || echo "  plugin skipped (already installed?): $plugin"
  done < "$SRC/plugins.txt"

  # Stack/domain plugins install disabled: defaultEnabled:false in the manifests
  # (honored since CLI 2.1.154 — below our documented floor of 2.1.187) plus explicit false entries
  # in global/settings.json enabledPlugins. Projects re-enable their own.
  echo "  stack plugins installed globally, disabled by default (enable per project)"
else
  echo "  WARNING: 'claude' CLI not found. Install Claude Code first (native installer, auto-updates):"
  echo "    curl -fsSL https://claude.ai/install.sh | bash"
  echo "  then re-run this script to register MCP servers and plugins."
fi

echo "Done. Open a NEW Claude Code session to load everything (check with /context, /mcp, /plugin)."
echo "Per project: run /setup-project inside each repo (new or legacy) to generate/audit its local config."
