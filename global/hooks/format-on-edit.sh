#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): auto-format the touched file by extension.
# Tolerant by design — silently no-ops when the formatter is not installed,
# so the same global config works on any machine.
# shellcheck disable=SC2015  # `cmd && fmt || true` is the whole point: never fail the hook
set -uo pipefail

input="$(cat)"
# JSON parsing: jq first (documented precondition), else any Python (python3 is not a
# given on Windows/Git Bash), else tolerant no-op.
PY="$(command -v python3 || command -v python || command -v py || true)"
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
elif [ -n "$PY" ]; then
  file="$(printf '%s' "$input" | "$PY" -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)"
else
  file=""
fi

if [ -z "$file" ] || [ ! -f "$file" ]; then
  echo '{}'
  exit 0
fi

find_node_bin() {
  # Walk up from the file's directory to find the project-local binary.
  local dir bin_name="$1"
  dir="$(dirname "$file")"
  while [ "$dir" != "/" ] && [ -n "$dir" ]; do
    if [ -x "$dir/node_modules/.bin/$bin_name" ]; then
      printf '%s' "$dir/node_modules/.bin/$bin_name"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

case "$file" in
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$file" >/dev/null 2>&1 || true
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
    if eslint_bin="$(find_node_bin eslint)"; then
      "$eslint_bin" --fix "$file" >/dev/null 2>&1 || true
    elif prettier_bin="$(find_node_bin prettier)"; then
      "$prettier_bin" --write "$file" >/dev/null 2>&1 || true
    fi
    ;;
  *.dart)
    command -v dart >/dev/null 2>&1 && dart format "$file" >/dev/null 2>&1 || true
    ;;
  *.kt|*.kts)
    command -v ktlint >/dev/null 2>&1 && ktlint -F "$file" >/dev/null 2>&1 || true
    ;;
  *.cs)
    if command -v csharpier >/dev/null 2>&1; then
      csharpier format "$file" >/dev/null 2>&1 || true
    elif command -v dotnet >/dev/null 2>&1; then
      dotnet csharpier format "$file" >/dev/null 2>&1 || true
    fi
    ;;
esac

echo '{}'
