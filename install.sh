#!/usr/bin/env bash
# Restores the Claude Code global configuration from this directory.
# Safe to re-run: it overwrites ~/.claude config files with the versions here.
# OWNER-ONLY: this replaces ~/.claude (CLAUDE.md, settings, hooks, statusline) with the
# owner's personal setup. To configure a single project or use only the plugins, do NOT
# run this — see AGENT-PROJECT-SETUP.md instead.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) echo "Unknown option: $arg (supported: --dry-run)"; exit 2 ;;
  esac
done

# The manifest records exactly what the copy block ships; computed once, shared by the
# dry-run preview and by the orphan pruning after the real copy.
MANIFEST="$DEST/.install-manifest"
new_manifest="$( (cd "$SRC/global" && find CLAUDE.md settings.json statusline.sh statusline.ps1 skills agents hooks rules -type f ! -name '.DS_Store') | LC_ALL=C sort )"

echo "Restoring Claude Code config: $SRC -> $DEST"
echo "  (owner-only: overwrites the global config; project setup lives in AGENT-PROJECT-SETUP.md)"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY-RUN: nothing will be written."
  for item in CLAUDE.md settings.json statusline.sh statusline.ps1 skills agents hooks rules; do
    if [ -e "$DEST/$item" ]; then
      echo "  would back up: $item -> $DEST/.backup-<timestamp>/"
    fi
  done
  echo "  would copy: global/{CLAUDE.md,settings.json,statusline.sh,statusline.ps1,skills,agents,hooks,rules} -> $DEST"
  if [ -f "$MANIFEST" ]; then
    while IFS= read -r rel; do
      if [ -z "$rel" ]; then continue; fi
      case "$rel" in /*|*..*) continue ;; esac
      if ! printf '%s\n' "$new_manifest" | grep -Fxq "$rel"; then
        echo "  would prune (no longer shipped): $rel"
      fi
    done < "$MANIFEST"
  fi
  lang_preview="${CLAUDE_LANGUAGE:-}"
  if [ -z "$lang_preview" ] && [ -f "$DEST/.install-profile" ]; then
    lang_preview="$(sed -n 's/^CLAUDE_LANGUAGE=//p' "$DEST/.install-profile" | tail -n 1)"
  fi
  echo "  would apply language: ${lang_preview:-spanish (default)}"
  echo "  would register: MCP servers from global/mcp-servers.json (user scope), dev-plugins marketplace, plugins from plugins.txt"
  exit 0
fi

mkdir -p "$DEST"

# --- Backup what this run will replace (last 3 backups kept) -------------------
ts="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEST/.backup-$ts"
for item in CLAUDE.md settings.json statusline.sh statusline.ps1 skills agents hooks rules; do
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
cp "$SRC/global/statusline.ps1" "$DEST/statusline.ps1"
chmod +x "$DEST/hooks/"*.sh "$DEST/statusline.sh"
find "$DEST/skills" "$DEST/agents" "$DEST/hooks" "$DEST/rules" -name ".DS_Store" -delete 2>/dev/null || true

# --- Orphan pruning (manifest-listed paths ONLY — never unknown user files) ----
# Files listed in a previous manifest but no longer shipped are removed, so
# renamed/deleted skills or rules stop loading into every session instead of
# lingering forever. MANIFEST/new_manifest are computed at the top (shared with the
# dry-run preview).
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

# --- Guards for the other agent CLIs ------------------------------------------
# The guard scripts speak three dialects (see global/hooks/lib/agent-io.sh), so the SAME
# file serves Claude Code, Codex CLI and Antigravity CLI. Only the registration differs.
# Registers ONLY into config dirs that already exist — never creates config for a CLI the
# user does not have — and MERGES with jq so hooks from other tools survive.
register_agent_guards() {
  local target="$1" matcher="$2" label="$3" tmp
  [ -f "$target" ] || printf '{}\n' > "$target"
  # Temp file next to the target, not in $TMPDIR: same filesystem (atomic mv) and the
  # directory is writable by definition, since we just wrote the target there.
  tmp="$target.tmp.$$"
  if jq --arg hooks_dir "$DEST/hooks" --arg matcher "$matcher" '
        # Drop any previous entries of ours, then re-add — keeps this idempotent and
        # leaves every foreign hook untouched.
        (.hooks.PreToolUse // []) as $existing
        | .hooks.PreToolUse = (
            [ $existing[] | select(
                [ (.hooks // [])[] | .command ] | any(test("guard-(shell-edit|git-push|git-add-all)")) | not
              ) ]
            + [ { matcher: $matcher,
                  hooks: [ "guard-shell-edit", "guard-git-push", "guard-git-add-all" ]
                         | map({ type: "command", command: ("bash \"" + $hooks_dir + "/" + . + ".sh\"") }) } ]
          )
      ' "$target" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    mv "$tmp" "$target"
    echo "  guards registered for $label ($target)"
  else
    rm -f "$tmp"
    echo "  NOTE: could not register guards for $label — left $target untouched."
  fi
}

if command -v jq >/dev/null 2>&1; then
  # Codex CLI: same hook contract as Claude Code, tool name "Bash".
  [ -d "$HOME/.codex" ] && register_agent_guards "$HOME/.codex/hooks.json" "Bash" "Codex CLI"
  # Antigravity CLI (agy): its shell tool is "run_command"; the scripts detect the dialect.
  [ -d "$HOME/.gemini/config" ] && register_agent_guards "$HOME/.gemini/config/hooks.json" "run_command" "Antigravity CLI"
fi

# --- Secrets -------------------------------------------------------------------
# secrets.env is sourced here and injected directly into the MCP registration
# below (~/.claude.json, machine-local, never committed). Note: a user-level
# settings.local.json is NOT read by Claude Code (only project-level is) — never
# rely on an env block there.
if [ -f "$SRC/secrets.env" ]; then
  # set -a: exported so the python JSON resolver below sees the keys too.
  set -a
  # shellcheck disable=SC1091
  source "$SRC/secrets.env"
  set +a
else
  echo "  NOTE: secrets.env not found — keyed MCP servers (if any in global/mcp-servers.json) register keyless."
fi

# --- MCP servers (user scope) + plugins --------------------------------------
if command -v claude >/dev/null 2>&1; then
  # Data-driven: every server in global/mcp-servers.json registers at user scope; each
  # env var it declares resolves from secrets.env when present and is dropped when not
  # (the server still registers, keyless). Adding a keyed server = one JSON entry + one
  # secrets.env line, zero installer changes.
  if command -v jq >/dev/null 2>&1; then
    server_names="$(jq -r '.mcpServers | keys[]' "$SRC/global/mcp-servers.json")"
  elif [ -n "$PY" ]; then
    server_names="$("$PY" -c "
import json
print('\n'.join(json.load(open('$SRC/global/mcp-servers.json'))['mcpServers']))")"
  else
    server_names=""
    echo "  WARNING: neither jq nor python found — register MCP servers manually: claude mcp add-json <name> '<json from global/mcp-servers.json, with your real keys in env>' --scope user"
  fi
  while IFS= read -r name; do
    if [ -z "$name" ]; then continue; fi
    if command -v jq >/dev/null 2>&1; then
      server_json="$(jq -c --arg n "$name" '.mcpServers[$n]' "$SRC/global/mcp-servers.json")"
      while IFS= read -r envkey; do
        if [ -z "$envkey" ]; then continue; fi
        val="${!envkey:-}"
        if [ -n "$val" ]; then
          server_json="$(printf '%s' "$server_json" | jq -c --arg k "$envkey" --arg v "$val" '.env[$k] = $v')"
        else
          server_json="$(printf '%s' "$server_json" | jq -c --arg k "$envkey" 'del(.env[$k])')"
        fi
      done < <(jq -r --arg n "$name" '.mcpServers[$n].env // {} | keys[]' "$SRC/global/mcp-servers.json")
      server_json="$(printf '%s' "$server_json" | jq -c 'if (.env // {}) == {} then del(.env) else . end')"
    else
      server_json="$(MCP_NAME="$name" "$PY" -c "
import json, os
s = json.load(open('$SRC/global/mcp-servers.json'))['mcpServers'][os.environ['MCP_NAME']]
env = s.get('env') or {}
resolved = {k: os.environ[k] for k in env if os.environ.get(k)}
if resolved:
    s['env'] = resolved
else:
    s.pop('env', None)
print(json.dumps(s))")"
    fi
    case "$server_json" in
      *'"env"'*) key_state="with API key" ;;
      *) key_state="keyless" ;;
    esac
    # Remove-then-add so config/key updates take effect (add-json fails if it exists).
    claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
    if claude mcp add-json "$name" "$server_json" --scope user 2>/dev/null; then
      echo "  MCP: $name registered (user scope, $key_state)"
    else
      echo "  MCP: $name registration failed — check with 'claude mcp list'"
    fi
  done <<< "$server_names"

  # Personal marketplace (this repo) — register or refresh, idempotent.
  # shellcheck disable=SC2015  # echo as the && branch cannot fail
  claude plugin marketplace add "$SRC" 2>/dev/null \
    && echo "  marketplace: dev-plugins registered" \
    || { claude plugin marketplace update dev-plugins 2>/dev/null \
         && echo "  marketplace: dev-plugins refreshed" \
         || echo "  marketplace: could not register — check 'claude plugin marketplace list'"; }

  while IFS= read -r plugin; do
    case "$plugin" in ''|\#*) continue ;; esac
    claude plugin install "$plugin" 2>/dev/null \
      && echo "  plugin installed: $plugin" \
      || echo "  plugin skipped (already installed?): $plugin"
  done < "$SRC/plugins.txt"

  # `claude plugin install` turns a plugin ON unless its manifest sets defaultEnabled:false.
  # The dev-plugins manifests do; the official ones (LSPs, expo) do NOT, so installing them
  # silently re-enables what global/settings.json just set to false. Re-apply the repo's
  # enabledPlugins block afterwards so the "nothing is enabled globally" policy holds: a
  # language server loaded in a project of another language is pure context cost, and every
  # plugin — LSPs included — is enabled per project in its own .claude/settings.json.
  if command -v jq >/dev/null 2>&1; then
    dest_settings="$DEST/settings.json"
    tmp_settings="$dest_settings.tmp.$$"
    if jq --slurpfile src "$SRC/global/settings.json" \
         '.enabledPlugins = ($src[0].enabledPlugins // {})' \
         "$dest_settings" > "$tmp_settings" 2>/dev/null && [ -s "$tmp_settings" ]; then
      mv "$tmp_settings" "$dest_settings"
    else
      rm -f "$tmp_settings"
      echo "  WARNING: could not re-apply enabledPlugins — check '$dest_settings' by hand."
    fi
  fi
  echo "  plugins installed globally, all disabled (each project enables what its stack needs)"
else
  echo "  WARNING: 'claude' CLI not found. Install Claude Code first (native installer, auto-updates):"
  echo "    curl -fsSL https://claude.ai/install.sh | bash"
  echo "  then re-run this script to register MCP servers and plugins."
fi

echo "Done. Open a NEW Claude Code session to load everything (check with /context, /mcp, /plugin)."
echo "Per project: run /setup-project inside each repo (new or legacy) to generate/audit its local config."
