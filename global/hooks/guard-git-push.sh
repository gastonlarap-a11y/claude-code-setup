#!/usr/bin/env bash
# PreToolUse hook (Bash, if: git *): deterministically enforce the global rule
# "never push directly to main". Denies `git push` when the target branch is
# main/master — either named in the command or implied by the checked-out branch.
# Fail-open by design: if anything cannot be parsed, the command proceeds and the
# prose rule + permission deny list (force push) still apply.
set -uo pipefail

# shellcheck source=lib/agent-io.sh disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/lib/agent-io.sh" 2>/dev/null || { echo '{}'; exit 0; }

hook_read_command
cmd="${HOOK_CMD:-}"
[ -n "$cmd" ] || hook_allow

cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // .workspaceRoot // empty' 2>/dev/null || true)"
fi

case "$cmd" in
  *"git push"*) ;;
  *) hook_allow ;;
esac

deny() {
  hook_deny "Blocked by policy (global CLAUDE.md): never push directly to main/master. Push from a feature branch; if this push is really intended, the user must run it themselves in a terminal."
}

# Analyze the segment after the last `git push`, up to the first command separator OR the
# end of that line. `head -n1` is not cosmetic: sed cuts per line, so without it a
# multi-line command bled into the next line and any later `main` (e.g. `gh pr create
# --base main`) was read as a refspec and denied.
segment="${cmd##*git push}"
segment="$(printf '%s' "$segment" | head -n1 | sed 's/[;&|].*$//')"
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

hook_allow
