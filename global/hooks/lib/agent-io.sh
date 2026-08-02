#!/usr/bin/env bash
# Shared hook I/O for the three agent CLIs that speak the PreToolUse-hook pattern.
# Sourced by the guard hooks so the dialect lives in ONE place: when a vendor changes its
# contract, this file is the only edit.
#
#   Claude Code / Codex CLI  — identical contract, field for field:
#       in : {"tool_input": {"command": "..."}}
#       out: {"hookSpecificOutput": {"hookEventName": "PreToolUse",
#             "permissionDecision": "deny"|"allow", "permissionDecisionReason": "..."}}
#   Antigravity CLI (agy)    — equivalent, different names:
#       in : {"toolCall": {"args": {"CommandLine": "..."}}}
#       out: {"decision": "deny"|"allow", "reason": "..."}
#
# Every function is fail-open: an unparseable payload yields an empty command, and callers
# must treat that as "allow". Never let a guard break a session.

# Populates HOOK_CMD (the shell command under inspection), HOOK_DIALECT ("claude" — also
# Codex — or "antigravity") and HOOK_INPUT (the raw payload, for callers that need another
# field such as .cwd). Reads stdin.
hook_read_command() {
  local input py
  input="$(cat)"
  # shellcheck disable=SC2034  # consumed by the sourcing hook (e.g. guard-git-push reads .cwd)
  HOOK_INPUT="$input"
  HOOK_CMD=""
  HOOK_DIALECT="claude"

  py="$(command -v python3 || command -v python || command -v py || true)"
  if command -v jq >/dev/null 2>&1; then
    HOOK_CMD="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
    if [ -z "$HOOK_CMD" ]; then
      HOOK_CMD="$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null || true)"
      [ -n "$HOOK_CMD" ] && HOOK_DIALECT="antigravity"
    fi
  elif [ -n "$py" ]; then
    HOOK_CMD="$(printf '%s' "$input" | "$py" -c "
import json,sys
try: d = json.load(sys.stdin)
except Exception: sys.exit(0)
c = d.get('tool_input', {}).get('command', '')
if c: print('claude\t' + c)
else:
    c = d.get('toolCall', {}).get('args', {}).get('CommandLine', '')
    if c: print('antigravity\t' + c)
" 2>/dev/null || true)"
    case "$HOOK_CMD" in
      antigravity*) HOOK_DIALECT="antigravity" ;;
    esac
    HOOK_CMD="${HOOK_CMD#*$'\t'}"
    case "$HOOK_CMD" in claude|antigravity) HOOK_CMD="" ;; esac
  fi
}

# Let the tool call proceed.
hook_allow() {
  if [ "${HOOK_DIALECT:-claude}" = "antigravity" ]; then
    printf '{"decision": "allow"}\n'
  else
    printf '{}\n'
  fi
  exit 0
}

# Block the tool call. $1 is the reason — write it as an instruction, since the model reads
# it and retries: say what to do instead, not just what went wrong.
hook_deny() {
  local reason="$1" escaped
  # JSON-escape: backslashes first, then quotes, then newlines.
  escaped="$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')"
  if [ "${HOOK_DIALECT:-claude}" = "antigravity" ]; then
    printf '{"decision": "deny", "reason": "%s"}\n' "$escaped"
  else
    printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "%s"}}\n' "$escaped"
  fi
  exit 0
}
