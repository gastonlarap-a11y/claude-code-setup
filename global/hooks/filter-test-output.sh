#!/usr/bin/env bash
# PreToolUse hook (Bash): when the command is a known test runner, rewrite it
# to run through run-test-filtered.sh so passing-test noise never reaches the
# model's context (official pattern from code.claude.com/docs/en/costs.md).
set -uo pipefail

input="$(cat)"
# JSON parsing: jq first (documented precondition), else any Python (python3 is not a
# given on Windows/Git Bash), else tolerant no-op (command runs unfiltered).
PY="$(command -v python3 || command -v python || command -v py || true)"
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
elif [ -n "$PY" ]; then
  cmd="$(printf '%s' "$input" | "$PY" -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || true)"
else
  cmd=""
fi

case "$cmd" in
  "npm test"*|"npm run test"*|"pnpm test"*|"pnpm run test"*|"go test"*|"flutter test"*|"npx jest"*|"./gradlew test"*)
    # Skip rewriting compound commands — wrapping them would change semantics.
    if printf '%s' "$cmd" | grep -Eq '[;&|><]'; then
      echo '{}'
      exit 0
    fi
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$cmd" | jq -Rs '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: {command: ("bash \"$HOME/.claude/hooks/run-test-filtered.sh\" " + (. | @sh))}}}'
    elif [ -n "$PY" ]; then
      # shellcheck disable=SC2016  # $HOME must stay literal: the shell expands it when the hook command runs
      printf '%s' "$cmd" | "$PY" -c '
import json, shlex, sys
cmd = sys.stdin.read()
wrapper = "bash \"$HOME/.claude/hooks/run-test-filtered.sh\" " + shlex.quote(cmd)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "updatedInput": {"command": wrapper},
    }
}))
'
    else
      echo '{}'
    fi
    ;;
  *)
    echo '{}'
    ;;
esac
