#!/usr/bin/env bash
# PreToolUse hook (Bash): when the command is a known test runner, rewrite it
# to run through run-test-filtered.sh so passing-test noise never reaches the
# model's context (official pattern from code.claude.com/docs/en/costs.md).
set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || true)"

case "$cmd" in
  "npm test"*|"npm run test"*|"pnpm test"*|"pnpm run test"*|"go test"*|"flutter test"*|"npx jest"*|"./gradlew test"*)
    # Skip rewriting compound commands — wrapping them would change semantics.
    if printf '%s' "$cmd" | grep -Eq '[;&|><]'; then
      echo '{}'
      exit 0
    fi
    printf '%s' "$cmd" | python3 -c '
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
    ;;
  *)
    echo '{}'
    ;;
esac
