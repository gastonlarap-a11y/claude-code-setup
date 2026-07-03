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
  || echo "  WARNING: jq not found (brew install jq) — statusline will be minimal."

# --- Secrets -> ~/.claude/settings.local.json (env block, machine-local) ----
if [ -f "$SRC/secrets.env" ]; then
  # shellcheck disable=SC1091
  source "$SRC/secrets.env"
  python3 - "$DEST/settings.local.json" <<'PYEOF'
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
else
  echo "  WARNING: secrets.env not found — copy secrets.env.example to secrets.env and re-run."
fi

# --- MCP servers (user scope) + plugins --------------------------------------
if command -v claude >/dev/null 2>&1; then
  ctx7_json="$(python3 -c "import json;d=json.load(open('$SRC/global/mcp-servers.json'));print(json.dumps(d['mcpServers']['context7']))")"
  claude mcp add-json context7 "$ctx7_json" --scope user 2>/dev/null \
    && echo "  MCP: context7 registered (user scope)" \
    || echo "  MCP: context7 already exists or CLI refused — check with 'claude mcp list'"

  # Personal marketplace (this repo) — register or refresh, idempotent.
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

  # Safety belt for Claude Code < 2.1.154 (ignores defaultEnabled: false and
  # enables on install): force stack plugins off at user scope; projects
  # re-enable them via their own .claude/settings.json.
  for p in expo@claude-plugins-official nestjs@gaston-plugins go@gaston-plugins \
           android-kotlin@gaston-plugins react-nextjs@gaston-plugins \
           flutter@gaston-plugins react-native@gaston-plugins \
           api-design@gaston-plugins bots@gaston-plugins \
           realtime@gaston-plugins background-jobs@gaston-plugins; do
    claude plugin disable "$p" --scope user >/dev/null 2>&1 || true
  done
  echo "  stack plugins installed globally, disabled by default (enable per project)"
else
  echo "  WARNING: 'claude' CLI not found. Install Claude Code first:"
  echo "    npm install -g @anthropic-ai/claude-code"
  echo "  then re-run this script to register MCP servers and plugins."
fi

echo "Done. Open a NEW Claude Code session to load everything (check with /context, /mcp, /plugin)."
echo "Per project: run /setup-project inside each repo (new or legacy) to generate/audit its local config."
