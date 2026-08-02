#!/usr/bin/env bash
# PreToolUse hook (Bash, if: git *): deterministically back the global rule "never
# commit secrets". Denies bulk staging — `git add -A`, `git add --all`, `git add .`,
# `git add :/` — which can sweep secrets or runtime files into the index unseen.
# Targeted staging (git add <path>) and `git add -u` (tracked files only) pass.
# Fail-open by design: if anything cannot be parsed, the command proceeds and the
# prose rule + the secrets deny list still apply.
set -uo pipefail

# shellcheck source=lib/agent-io.sh disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/lib/agent-io.sh" 2>/dev/null || { echo '{}'; exit 0; }

hook_read_command
cmd="${HOOK_CMD:-}"
[ -n "$cmd" ] || hook_allow

case "$cmd" in
  *"git add"*) ;;
  *) hook_allow ;;
esac

deny() {
  hook_deny "Blocked by policy: bulk staging (git add -A/--all/./:/) can sweep secrets or runtime files into the commit unseen. Stage the intended paths by name (git add <file> ...); if bulk staging is really intended, the user must run it themselves in a terminal."
}

# Analyze the segment after the last `git add` up to any command separator.
segment="${cmd##*git add}"
# head -n1 first: sed cuts per line, so a multi-line command would otherwise bleed into
# the next line and read its tokens as arguments to this `git add`.
segment="$(printf '%s' "$segment" | head -n1 | sed 's/[;&|].*$//')"
set -f  # no globbing while tokenizing: the command may contain * or ?

for tok in $segment; do
  case "$tok" in
    -A|--all|.|:/) deny ;;
  esac
done

hook_allow
