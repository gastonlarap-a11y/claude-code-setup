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
# A command can be scoped to the area it verifies with `<globs>::<command>`, so a repo that
# mixes stacks does not pay the web checks on a turn that only touched the backend:
#   'renderer/**::pnpm -C renderer typecheck'   'src/**,*.slnx::dotnet build'
# Comma-separates several globs; they are matched against `git status --porcelain`, i.e.
# relative to the REPO ROOT, and `*` crosses `/` (shell `case` semantics, not globstar).
# An argument with no `::` — or whose prefix contains whitespace, so `--filter A::B` keeps
# working — always runs. Nothing changed in the working tree means the scoped commands are
# skipped; when git cannot answer at all, everything runs.
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
if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  echo '{}'
  exit 0
fi
cd "$dir" 2>/dev/null || { echo '{}'; exit 0; }

# Split every argument into its optional scope and its command.
globs_list=()
cmds_list=()
need_scope=0
for arg in "$@"; do
  [ -n "$arg" ] || continue
  globs=""
  cmd="$arg"
  case "$arg" in
    *"::"*)
      prefix="${arg%%::*}"
      # A prefix with whitespace is part of the command (`dotnet test --filter A::B`).
      case "$prefix" in
        ""|*[[:space:]]*) : ;;
        *) globs="$prefix"; cmd="${arg#*::}" ;;
      esac
      ;;
  esac
  [ -n "$cmd" ] || continue
  globs_list+=("$globs")
  cmds_list+=("$cmd")
  [ -z "$globs" ] || need_scope=1
done

[ "${#cmds_list[@]}" -gt 0 ] || { echo '{}'; exit 0; }

# The Stop payload carries no file list, so the turn's footprint is read off the working tree.
changed=()
scope_known=0
if [ "$need_scope" -eq 1 ] &&
  command -v git >/dev/null 2>&1 &&
  git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  skip_next=0
  while IFS= read -r -d '' record; do
    if [ "$skip_next" -eq 1 ]; then
      skip_next=0
      continue
    fi
    # Porcelain v1: "XY path"; a rename/copy emits the original path as a second record.
    case "${record:0:2}" in
      R*|C*|?R|?C) skip_next=1 ;;
    esac
    path="${record:3}"
    [ -z "$path" ] || changed+=("$path")
  done < <(git status --porcelain -z 2>/dev/null)
  scope_known=1
fi

# Split on commas with parameter expansion only: an array assignment would pathname-expand
# `renderer/**` against the working directory and match the wrong thing (or nothing).
scope_hit() {
  [ "${#changed[@]}" -gt 0 ] || return 1
  local rest="$1," pattern file
  while [ -n "$rest" ]; do
    pattern="${rest%%,*}"
    rest="${rest#*,}"
    [ -n "$pattern" ] || continue
    for file in "${changed[@]}"; do
      # shellcheck disable=SC2254 # unquoted on purpose: $pattern is a glob, not a literal
      case "$file" in $pattern) return 0 ;; esac
    done
  done
  return 1
}

i=0
while [ "$i" -lt "${#cmds_list[@]}" ]; do
  globs="${globs_list[$i]}"
  cmd="${cmds_list[$i]}"
  i=$((i + 1))
  if [ -n "$globs" ] && [ "$scope_known" -eq 1 ] && ! scope_hit "$globs"; then
    continue
  fi
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
