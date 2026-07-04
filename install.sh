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

cp "$SRC/global/CLAUDE.md" "$DEST/CLAUDE.md"
cp "$SRC/global/settings.json" "$DEST/settings.json"
cp -R "$SRC/global/skills" "$DEST/"
cp -R "$SRC/global/agents" "$DEST/"
cp -R "$SRC/global/hooks" "$DEST/"
cp -R "$SRC/global/rules" "$DEST/"
cp "$SRC/global/statusline.sh" "$DEST/statusline.sh"
chmod +x "$DEST/hooks/"*.sh "$DEST/statusline.sh"
find "$DEST/skills" "$DEST/agents" "$DEST/hooks" "$DEST/rules" -name ".DS_Store" -delete 2>/dev/null || true

command -v jq >/dev/null 2>&1 \
  || echo "  WARNING: jq not found — statusline will be minimal. Install: brew install jq (macOS) / winget install jqlang.jq (Windows) / sudo apt install jq (Linux)."

# Any Python works for the JSON merges below; python3 is not a given on Windows/Git Bash.
PY="$(command -v python3 || command -v python || command -v py || true)"

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
  # (honored since CLI 2.1.154, our documented minimum) plus explicit false entries
  # in global/settings.json enabledPlugins. Projects re-enable their own.
  echo "  stack plugins installed globally, disabled by default (enable per project)"
else
  echo "  WARNING: 'claude' CLI not found. Install Claude Code first (native installer, auto-updates):"
  echo "    curl -fsSL https://claude.ai/install.sh | bash"
  echo "  then re-run this script to register MCP servers and plugins."
fi

echo "Done. Open a NEW Claude Code session to load everything (check with /context, /mcp, /plugin)."
echo "Per project: run /setup-project inside each repo (new or legacy) to generate/audit its local config."
