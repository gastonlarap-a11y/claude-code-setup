#!/usr/bin/env bash
# CI guard for the dual-bump rule: every entry in .claude-plugin/marketplace.json must
# match the plugin's own .claude-plugin/plugin.json (same name, same version), and every
# @gaston-plugins line in plugins.txt must exist in the marketplace. Requires jq.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
marketplace=".claude-plugin/marketplace.json"

while IFS=$'\t' read -r name version source; do
  manifest="${source#./}/.claude-plugin/plugin.json"
  if [ ! -f "$manifest" ]; then
    echo "FAIL: $name -> $manifest not found"
    fail=1
    continue
  fi
  plugin_name="$(jq -r '.name' "$manifest")"
  plugin_version="$(jq -r '.version' "$manifest")"
  if [ "$plugin_name" != "$name" ]; then
    echo "FAIL: marketplace entry '$name' but $manifest declares name '$plugin_name'"
    fail=1
  fi
  if [ "$plugin_version" != "$version" ]; then
    echo "FAIL: version drift for '$name' — marketplace $version vs plugin.json $plugin_version (dual-bump rule)"
    fail=1
  fi
done < <(jq -r '.plugins[] | [.name, .version, .source] | @tsv' "$marketplace")

while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  case "$line" in
    *@gaston-plugins)
      name="${line%@gaston-plugins}"
      if ! jq -e --arg n "$name" '.plugins[] | select(.name == $n)' "$marketplace" >/dev/null; then
        echo "FAIL: plugins.txt lists '$line' but the marketplace has no plugin named '$name'"
        fail=1
      fi
      ;;
  esac
done < plugins.txt

if [ "$fail" -eq 0 ]; then
  echo "OK: marketplace, plugin manifests and plugins.txt are consistent"
fi
exit "$fail"
