#!/usr/bin/env bash
# CI guard (feature branches): any change under plugins/<name>/ must come with a version
# bump in that plugin's .claude-plugin/plugin.json in the same diff. Complements
# check-versions.sh (parity marketplace<->plugin.json) by catching the forgotten bump
# itself. Requires git + jq. Base ref: first argument, default origin/main.
set -euo pipefail
cd "$(dirname "$0")/.."

base="${1:-origin/main}"

if ! git rev-parse --verify --quiet "$base" >/dev/null; then
  echo "SKIP: base ref '$base' not available (shallow clone?) — cannot check version bumps"
  exit 0
fi

changed_plugins="$(git diff --name-only "$base"...HEAD -- 'plugins/' | awk -F/ 'NF>=2 {print $2}' | sort -u)"

if [ -z "$changed_plugins" ]; then
  echo "OK: no plugin changes vs $base"
  exit 0
fi

fail=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  manifest="plugins/$name/.claude-plugin/plugin.json"
  if [ ! -f "$manifest" ]; then
    continue  # plugin removed in this diff — check-versions.sh covers consistency
  fi
  head_version="$(jq -r '.version // empty' "$manifest")"
  base_version="$(git show "$base:$manifest" 2>/dev/null | jq -r '.version // empty' || true)"
  if [ -z "$base_version" ]; then
    continue  # plugin is new in this diff — nothing to bump against
  fi
  if [ "$head_version" = "$base_version" ]; then
    echo "FAIL: plugins/$name changed but its version stayed at $base_version — bump plugin.json AND marketplace.json (dual-bump rule)"
    fail=1
  fi
done <<< "$changed_plugins"

if [ "$fail" -eq 0 ]; then
  echo "OK: every changed plugin bumped its version vs $base"
fi
exit "$fail"
