#!/usr/bin/env bash
# ConfigChange hook: append-only audit trail (~/.claude/config-audit.log) of config
# changes detected during sessions. The event covers user/project/local/policy settings
# and skills; CLAUDE.md/rules changes fire InstructionsLoaded instead (no change
# detection exists for them), so this is a partial compensating control for the missing
# integrity check on ~/.claude (anthropics/claude-code#21674, closed "not planned").
# Log-only: never blocks. Trim the log manually if it ever grows.
set -uo pipefail

input="$(cat)"
log="${CLAUDE_CONFIG_AUDIT_LOG:-$HOME/.claude/config-audit.log}"
PY="$(command -v python3 || command -v python || command -v py || true)"
if command -v jq >/dev/null 2>&1; then
  line="$(printf '%s' "$input" | jq -r '[(now | todate), (.source // "?"), (.file_path // "?")] | join("  ")' 2>/dev/null || true)"
elif [ -n "$PY" ]; then
  line="$(printf '%s' "$input" | "$PY" -c "
import json, sys, datetime
d = json.load(sys.stdin)
ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
print('  '.join([ts, d.get('source', '?'), d.get('file_path', '?')]))" 2>/dev/null || true)"
else
  line=""
fi
if [ -n "$line" ]; then
  printf '%s\n' "$line" >> "$log" 2>/dev/null || true
fi
echo '{}'
