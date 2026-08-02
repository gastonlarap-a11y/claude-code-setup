#!/usr/bin/env bash
# Stop hook: the end-of-turn quality gate.
#
# Every other guard here checks the CONFIG or the COMMAND. This one checks the WORK: it runs
# the project's own cheap checks when the turn is about to close and, if one fails, refuses to
# let the turn end — handing the failure back to the model while the context is still alive.
# Without it, "run lint/typecheck before declaring done" is a prose instruction the model has
# to remember; with it, it is a deterministic sensor.
#
# Generic on purpose: each repo declares ITS commands in .claude/settings.json, e.g.
#   "Stop": [{ "hooks": [{ "type": "command", "timeout": 180,
#     "command": "bash \"$HOME/.claude/hooks/verify-turn.sh\" 'pnpm typecheck' 'pnpm lint'" }] }]
#
# Keep the commands cheap (typecheck, lint). Full suites belong in CI and in the `verify`
# skill — a gate that costs minutes trains you to disable it.
# Fail-open: anything unexpected lets the turn close.
set -uo pipefail

[ "$#" -gt 0 ] || { echo '{}'; exit 0; }

input="$(cat)"

# stop_hook_active is set when the turn is already being re-run because of a Stop hook.
# Without this guard a failing check loops forever, burning tokens.
if command -v jq >/dev/null 2>&1; then
  active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
else
  case "$input" in *'"stop_hook_active":true'*) active=true ;; *) active=false ;; esac
  cwd=""
fi
[ "$active" != "true" ] || { echo '{}'; exit 0; }

dir="${CLAUDE_PROJECT_DIR:-$cwd}"
[ -n "$dir" ] && [ -d "$dir" ] || { echo '{}'; exit 0; }
cd "$dir" 2>/dev/null || { echo '{}'; exit 0; }

for cmd in "$@"; do
  [ -n "$cmd" ] || continue
  if ! out="$(eval "$cmd" 2>&1)"; then
    # Hand back the tail: enough to act on, not the whole build log.
    detail="$(printf '%s' "$out" | tail -n 40)"
    reason="$(printf 'Turn blocked: \x60%s\x60 failed. Fix it before finishing — the work is not done while this is red.\n\n%s' "$cmd" "$detail")"
    if command -v jq >/dev/null 2>&1; then
      jq -nc --arg r "$reason" '{decision: "block", reason: $r}'
    else
      printf '{"decision": "block", "reason": "%s"}\n' \
        "$(printf '%s' "$reason" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')"
    fi
    exit 0
  fi
done

echo '{}'
