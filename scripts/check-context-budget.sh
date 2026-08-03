#!/usr/bin/env bash
# Context-budget guard. global/CLAUDE.md is paid on EVERY session of every project, and
# paths-scoped rules are paid whenever a matching file is touched — so both have a hard
# ceiling. Guards against Context Bloat, the smell measured in 42% of real repos
# (arXiv:2606.15828), and matches the budgets setup-project already documents.
# Fails loud (CI script, not a hook).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CLAUDE_MD_WARN=40
CLAUDE_MD_FAIL=45
RULE_FAIL=40

status=0

claude_md="$root/global/CLAUDE.md"
lines="$(wc -l < "$claude_md" | tr -d ' ')"
if [ "$lines" -gt "$CLAUDE_MD_FAIL" ]; then
  echo "check-context-budget: global/CLAUDE.md is $lines lines (max $CLAUDE_MD_FAIL)." >&2
  echo "  It loads in every session. Move procedures to a skill, per-language guidance to" >&2
  echo "  a paths-scoped rule, and guarantees to a hook or permissions.deny." >&2
  status=1
elif [ "$lines" -gt "$CLAUDE_MD_WARN" ]; then
  echo "check-context-budget: WARNING global/CLAUDE.md is $lines lines (soft limit $CLAUDE_MD_WARN)."
else
  echo "check-context-budget: global/CLAUDE.md OK ($lines/$CLAUDE_MD_FAIL lines)"
fi

# Every global skill puts its name and `description` in the system prompt of EVERY session of
# EVERY project, whether or not the skill is ever opened — the only always-on cost a skill has.
# There is no per-skill disable in the CLI, so the lever is: stay global and stay short, or move
# to a plugin the project enables. This ceiling is what makes that choice deliberate.
SKILL_DESC_WARN=2800
SKILL_DESC_FAIL=3200

desc_chars=0
for skill in "$root"/global/skills/*/SKILL.md; do
  [ -e "$skill" ] || continue
  n="$(grep -m1 '^description:' "$skill" | wc -c | tr -d ' ')"
  desc_chars=$((desc_chars + n))
done
if [ "$desc_chars" -gt "$SKILL_DESC_FAIL" ]; then
  echo "check-context-budget: global skill descriptions total $desc_chars chars (max $SKILL_DESC_FAIL)." >&2
  echo "  Every project pays this on every session. Shorten the descriptions to their trigger" >&2
  echo "  words, or move a stack-specific skill into a plugin enabled per project." >&2
  status=1
elif [ "$desc_chars" -gt "$SKILL_DESC_WARN" ]; then
  echo "check-context-budget: WARNING global skill descriptions total $desc_chars chars (soft limit $SKILL_DESC_WARN)."
else
  echo "check-context-budget: global skill descriptions OK ($desc_chars/$SKILL_DESC_FAIL chars)"
fi

for rule in "$root"/global/rules/*.md; do
  [ -e "$rule" ] || continue
  rl="$(wc -l < "$rule" | tr -d ' ')"
  if [ "$rl" -gt "$RULE_FAIL" ]; then
    echo "check-context-budget: $(basename "$rule") is $rl lines (max $RULE_FAIL)." >&2
    status=1
  fi
done

[ "$status" -eq 0 ] && echo "check-context-budget: rules within budget"
exit "$status"
