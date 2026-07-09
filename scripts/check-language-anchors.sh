#!/usr/bin/env bash
# CI guard: the anchor literals the installers rewrite (scripts/language-anchors.env)
# must exist verbatim in the source files — a reworded source would otherwise silently
# disable the CLAUDE_LANGUAGE rewrite at install time.
set -euo pipefail
cd "$(dirname "$0")/.."

# shellcheck disable=SC1091
. scripts/language-anchors.env

fail=0
if ! grep -qF "$CLAUDE_MD_LANGUAGE_ANCHOR" global/CLAUDE.md; then
  echo "FAIL: anchor not found in global/CLAUDE.md: $CLAUDE_MD_LANGUAGE_ANCHOR"
  fail=1
fi
if ! grep -qF "$SETTINGS_LANGUAGE_ANCHOR" global/settings.json; then
  echo "FAIL: anchor not found in global/settings.json: $SETTINGS_LANGUAGE_ANCHOR"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "OK: language anchors present in the sources"
fi
exit "$fail"
