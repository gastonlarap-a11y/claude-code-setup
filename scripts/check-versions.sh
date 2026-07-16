#!/usr/bin/env bash
# CI guard for the dual-bump rule: every entry in .claude-plugin/marketplace.json must
# match the plugin's own .claude-plugin/plugin.json (same name, same version), and every
# personal-marketplace line in plugins.txt must exist in the marketplace. Requires jq.
# The marketplace name is read from marketplace.json — single source, never hardcoded.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
marketplace=".claude-plugin/marketplace.json"
mkt="$(jq -r '.name' "$marketplace")"

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
    *"@$mkt")
      name="${line%@"$mkt"}"
      if ! jq -e --arg n "$name" '.plugins[] | select(.name == $n)' "$marketplace" >/dev/null; then
        echo "FAIL: plugins.txt lists '$line' but the marketplace has no plugin named '$name'"
        fail=1
      fi
      ;;
  esac
done < plugins.txt

# enabledPlugins <-> marketplace sync (global/settings.json): every marketplace plugin
# needs an explicit entry there (installed-but-disabled defaults), and every
# personal-marketplace key there must exist in the marketplace.
settings="global/settings.json"
while IFS= read -r name; do
  if ! jq -e --arg k "${name}@${mkt}" '.enabledPlugins | has($k)' "$settings" >/dev/null; then
    echo "FAIL: marketplace plugin '$name' has no enabledPlugins entry in $settings"
    fail=1
  fi
done < <(jq -r '.plugins[].name' "$marketplace")

while IFS= read -r key; do
  name="${key%@"$mkt"}"
  if ! jq -e --arg n "$name" '.plugins[] | select(.name == $n)' "$marketplace" >/dev/null; then
    echo "FAIL: $settings enables '$key' but the marketplace has no plugin named '$name'"
    fail=1
  fi
done < <(jq -r --arg s "@$mkt" '.enabledPlugins | keys[] | select(endswith($s))' "$settings")

if [ "$fail" -eq 0 ]; then
  echo "OK: marketplace, plugin manifests, plugins.txt and settings enabledPlugins are consistent"
fi
exit "$fail"
