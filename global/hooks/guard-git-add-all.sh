#!/usr/bin/env bash
# PreToolUse hook (Bash, if: git *): deterministically back the global rule "never
# commit secrets". Denies bulk staging — `git add -A`, `git add --all`, `git add .`,
# `git add :/` — which can sweep secrets or runtime files into the index unseen.
# Targeted staging (git add <path>) and `git add -u` (tracked files only) pass.
# Fail-open by design: if anything cannot be parsed, the command proceeds and the
# prose rule + the secrets deny list still apply.
set -uo pipefail

input="$(cat)"
PY="$(command -v python3 || command -v python || command -v py || true)"
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
elif [ -n "$PY" ]; then
  cmd="$(printf '%s' "$input" | "$PY" -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)"
else
  echo '{}'
  exit 0
fi

case "$cmd" in
  *"git add"*) ;;
  *) echo '{}'; exit 0 ;;
esac

deny() {
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Blocked by policy: bulk staging (git add -A/--all/./:/) can sweep secrets or runtime files into the commit unseen. Stage the intended paths by name (git add <file> ...); if bulk staging is really intended, the user must run it themselves in a terminal."}}
JSON
  exit 0
}

# Analyze the segment after the last `git add` up to any command separator.
segment="${cmd##*git add}"
segment="$(printf '%s' "$segment" | sed 's/[;&|].*$//')"
set -f  # no globbing while tokenizing: the command may contain * or ?

for tok in $segment; do
  case "$tok" in
    -A|--all|.|:/) deny ;;
  esac
done

echo '{}'
