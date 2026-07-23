#!/usr/bin/env bash
# CI guard: the config skeletons in setup-project's references/templates.md must stay
# syntactically valid — a hand edit that breaks a ```json (or ```toml) block would ship
# broken config to every project the protocol touches. Fence-aware: only TOP-LEVEL fenced
# blocks are validated (the README skeleton nests ``` blocks inside a ````markdown fence —
# those are content, not config). jq validates JSON; TOML is best-effort via python
# tomllib (skipped with a note when unavailable — degrade, never abort). Portable awk
# only (no gawk extensions): CI uses mawk, macOS uses BSD awk.
set -euo pipefail
cd "$(dirname "$0")/.."

file="global/skills/setup-project/references/templates.md"
# Explicit template: macOS mktemp ignores TMPDIR without one (uses confstr temp dir).
tmp="$(mktemp -d "${TMPDIR:-/tmp}/claude-templates.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

awk -v outdir="$tmp" '
  function fence_len(line,    n) {
    n = 0
    while (substr(line, n + 1, 1) == "`") n++
    return n
  }
  !in_block {
    if ($0 ~ /^```/) {
      flen = fence_len($0)
      lang = substr($0, flen + 1)
      gsub(/[[:space:]]/, "", lang)
      in_block = 1
      n++
      out = outdir "/" n "." (lang == "" ? "none" : lang)
      printf "" > out
    }
    next
  }
  {
    if ($0 ~ /^```+[[:space:]]*$/ && fence_len($0) >= flen) {
      in_block = 0
      close(out)
      next
    }
    print $0 >> out
  }
' "$file"

fail=0
json_count=0
shopt -s nullglob

for f in "$tmp"/*.json; do
  json_count=$((json_count + 1))
  if ! jq empty "$f" 2> "$tmp/err"; then
    echo "FAIL: invalid JSON in $file, fenced block $(basename "${f%.*}"):"
    sed 's/^/  /' "$tmp/err"
    fail=1
  fi
done
if [ "$json_count" -eq 0 ]; then
  echo "FAIL: no top-level \`\`\`json blocks found in $file — extraction broken or file restructured"
  fail=1
fi

PY="$(command -v python3 || command -v python || true)"
toml_checked=0
for f in "$tmp"/*.toml; do
  if [ -n "$PY" ] && "$PY" -c 'import tomllib' 2>/dev/null; then
    if ! "$PY" -c "import tomllib, sys; tomllib.load(open(sys.argv[1], 'rb'))" "$f" 2> "$tmp/err"; then
      echo "FAIL: invalid TOML in $file, fenced block $(basename "${f%.*}"):"
      sed 's/^/  /' "$tmp/err"
      fail=1
    fi
    toml_checked=$((toml_checked + 1))
  else
    echo "NOTE: python 3.11+ (tomllib) not available — skipping TOML validation for $(basename "$f")"
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: $json_count json block(s) valid, $toml_checked toml block(s) checked in $file"
fi
exit "$fail"
