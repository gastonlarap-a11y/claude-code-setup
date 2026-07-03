#!/usr/bin/env bash
# Runs the given test command but keeps its output small for the model:
# on success prints only the tail (summary lines); on failure prints only
# the lines around failures. Full output is never lost to the user's
# terminal history, only trimmed from the model's context.
set -uo pipefail

cmd="$1"
out="$(eval "$cmd" 2>&1)"
status=$?

if [ $status -eq 0 ]; then
  echo "PASSED (exit 0). Last lines of output:"
  printf '%s\n' "$out" | tail -8
else
  printf '%s\n' "$out" | grep -E -B 2 -A 10 '(FAIL|ERROR|error|✕|✗|Expected|panic:|--- FAIL)' | head -150
  echo "FAILED (exit $status) — output filtered to failure context by ~/.claude/hooks/run-test-filtered.sh"
fi

exit $status
