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

# --- Secrets -> ~/.claude/settings.local.json (env block, machine-local) ----
if [ -f "$SRC/secrets.env" ] && [ -n "$PY" ]; then
  # shellcheck disable=SC1091
  source "$SRC/secrets.env"
  "$PY" - "$DEST/settings.local.json" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
data = {}
if os.path.exists(path):
    try:
        data = json.load(open(path))
    except Exception:
        data = {}
env = data.setdefault("env", {})
key = os.environ.get("CONTEXT7_API_KEY", "")
if key:
    env["CONTEXT7_API_KEY"] = key
with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("  settings.local.json: secrets applied")
PYEOF
elif [ ! -f "$SRC/secrets.env" ]; then
  echo "  WARNING: secrets.env not found — copy secrets.env.example to secrets.env and re-run."
else
  echo "  WARNING: no python found — add the keys from secrets.env to the \"env\" block of $DEST/settings.local.json manually."
fi

# --- MCP servers (user scope) + plugins --------------------------------------
if command -v claude >/dev/null 2>&1; then
  if command -v jq >/dev/null 2>&1; then
    ctx7_json="$(jq -c '.mcpServers.context7' "$SRC/global/mcp-servers.json")"
  elif [ -n "$PY" ]; then
    ctx7_json="$("$PY" -c "import json;d=json.load(open('$SRC/global/mcp-servers.json'));print(json.dumps(d['mcpServers']['context7']))")"
  else
    ctx7_json=""
    echo "  WARNING: neither jq nor python found — register context7 manually: claude mcp add-json context7 '<json from global/mcp-servers.json>' --scope user"
  fi
  if [ -n "$ctx7_json" ]; then
    claude mcp add-json context7 "$ctx7_json" --scope user 2>/dev/null \
      && echo "  MCP: context7 registered (user scope)" \
      || echo "  MCP: context7 already exists or CLI refused — check with 'claude mcp list'"
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
