#!/usr/bin/env bash
# Consistency guard: the docs-researcher agent's frontmatter model must match the global
# CLAUDE_CODE_SUBAGENT_MODEL env var, so the file never claims a model the env var silently
# overrides. CLAUDE_CODE_SUBAGENT_MODEL has highest precedence over any agent frontmatter.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
settings="$root/global/settings.json"
agent="$root/global/agents/docs-researcher.md"

expected="$(jq -r '.env.CLAUDE_CODE_SUBAGENT_MODEL // empty' "$settings")"
actual="$(sed -n 's/^model:[[:space:]]*//p' "$agent" | head -n1)"

if [ -z "$expected" ]; then
  echo "check-subagent-model: env.CLAUDE_CODE_SUBAGENT_MODEL not set in $settings" >&2
  exit 1
fi
if [ "$actual" != "$expected" ]; then
  echo "check-subagent-model: docs-researcher model '$actual' != expected '$expected'" >&2
  exit 1
fi
echo "check-subagent-model: OK ($actual)"
