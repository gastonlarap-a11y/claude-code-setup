@AGENTS.md

## Claude Code specifics

- Subagent model is pinned by `env.CLAUDE_CODE_SUBAGENT_MODEL` (Sonnet) in
  `global/settings.json`, which overrides any agent's `model:` frontmatter. Keep
  `global/agents/*.md` in sync — `scripts/check-subagent-model.sh` enforces it in CI.
