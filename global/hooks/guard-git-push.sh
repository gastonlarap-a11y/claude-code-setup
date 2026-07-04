#!/usr/bin/env bash
# PreToolUse hook (Bash, if: git *): deterministically enforce the global rule
# "never push directly to main". Denies `git push` when the target branch is
# main/master — either named in the command or implied by the checked-out branch.
# Fail-open by design: if anything cannot be parsed, the command proceeds and the
# prose rule + permission deny list (force push) still apply.
set -uo pipefail

input="$(cat)"
PY="$(command -v python3 || command -v python || command -v py || true)"
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
elif [ -n "$PY" ]; then
  cmd="$(printf '%s' "$input" | "$PY" -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)"
  cwd="$(printf '%s' "$input" | "$PY" -c "import json,sys; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || true)"
else
  echo '{}'
  exit 0
fi

case "$cmd" in
  *"git push"*) ;;
  *) echo '{}'; exit 0 ;;
esac

deny() {
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Blocked by policy (global CLAUDE.md): never push directly to main/master. Push from a feature branch; if this push is really intended, the user must run it themselves in a terminal."}}
JSON
  exit 0
}

# Analyze the segment after the last `git push` up to any command separator.
segment="${cmd##*git push}"
segment="$(printf '%s' "$segment" | sed 's/[;&|].*$//')"
set -f  # no globbing while tokenizing: the command may contain * or ?

# Tokens that are not flags: first is the remote, the rest are refspecs.
refspecs=""
seen_remote=0
for tok in $segment; do
  case "$tok" in
    -*) continue ;;
    *)
      if [ "$seen_remote" -eq 0 ]; then seen_remote=1; else refspecs="$refspecs $tok"; fi
      ;;
  esac
done

# Explicit refspec targeting main/master (src, dst of src:dst, or deletion :dst).
for ref in $refspecs; do
  dst="${ref##*:}"
  case "$dst" in
    main|master|refs/heads/main|refs/heads/master) deny ;;
  esac
done

# No explicit branch (bare push, or HEAD): the checked-out branch decides.
need_branch_check=0
if [ -z "$refspecs" ]; then
  need_branch_check=1
else
  for ref in $refspecs; do
    case "$ref" in HEAD) need_branch_check=1 ;; esac
  done
fi

if [ "$need_branch_check" -eq 1 ] && [ -n "$cwd" ]; then
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
  case "$branch" in
    main|master) deny ;;
  esac
fi

echo '{}'
