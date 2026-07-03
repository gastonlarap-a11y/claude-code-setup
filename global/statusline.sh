#!/usr/bin/env bash
# Claude Code status line: [Model] dir | branch | ▓▓▓░░░░░░░ 34% ctx | 5h: 12% | 7d: 41%
# Receives session JSON on stdin (see code.claude.com/docs/en/statusline).
set -u

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  # Degraded fallback without jq: just show the working directory name.
  printf '%s' "$(basename "$PWD")"
  exit 0
fi

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // "."')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0 | floor')
five_h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor? // empty')
seven_d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | floor? // empty')

branch=$(git -C "$dir" branch --show-current 2>/dev/null)

# 10-char context usage bar with color thresholds.
filled=$((ctx / 10))
[ "$filled" -gt 10 ] && filled=10
bar=""
i=0
while [ $i -lt 10 ]; do
  if [ $i -lt "$filled" ]; then bar="${bar}▓"; else bar="${bar}░"; fi
  i=$((i + 1))
done

if [ "$ctx" -ge 85 ]; then color="\033[31m"   # red
elif [ "$ctx" -ge 60 ]; then color="\033[33m" # yellow
else color="\033[32m"; fi                      # green
reset="\033[0m"

out="[${model}] $(basename "$dir")"
[ -n "$branch" ] && out="${out} | ${branch}"
out="${out} | ${color}${bar} ${ctx}% ctx${reset}"
[ -n "$five_h" ] && out="${out} | 5h: ${five_h}%"
[ -n "$seven_d" ] && out="${out} | 7d: ${seven_d}%"

printf '%b' "$out"
