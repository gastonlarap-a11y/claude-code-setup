#!/usr/bin/env bash
# Notification hook (OPT-IN — shipped but NOT wired by default; wiring snippet in the
# README): shows an OS notification when Claude Code needs attention. stdin JSON carries
# message/title/notification_type; useful matchers: permission_prompt, idle_prompt.
# macOS: osascript · Linux: notify-send · native Windows: pending .ps1 hook parity —
# no-op when no notifier is available.
set -uo pipefail

input="$(cat)"
PY="$(command -v python3 || command -v python || command -v py || true)"
title="Claude Code"
message="Claude Code needs your attention"
if command -v jq >/dev/null 2>&1; then
  t="$(printf '%s' "$input" | jq -r '.title // empty' 2>/dev/null || true)"
  m="$(printf '%s' "$input" | jq -r '.message // empty' 2>/dev/null || true)"
elif [ -n "$PY" ]; then
  t="$(printf '%s' "$input" | "$PY" -c "import json,sys; print(json.load(sys.stdin).get('title',''))" 2>/dev/null || true)"
  m="$(printf '%s' "$input" | "$PY" -c "import json,sys; print(json.load(sys.stdin).get('message',''))" 2>/dev/null || true)"
else
  t=""
  m=""
fi
if [ -n "$t" ]; then title="$t"; fi
if [ -n "$m" ]; then message="$m"; fi

if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"${message//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$title" "$message" >/dev/null 2>&1 || true
fi
echo '{}'
