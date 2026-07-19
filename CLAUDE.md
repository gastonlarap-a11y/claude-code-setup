# claude-code-setup

Portable Claude Code configuration and the `dev-plugins` marketplace. Agent entry points:

- **Not sure / any machine, any user**: `START.md` — interactive bootstrap that detects
  the environment, interviews the user, and routes to the right procedure below.
- **Restore a machine (owner only)**: `AGENT-INSTALL.md` → runs `install.sh`, which
  OVERWRITES `~/.claude/`. Never suggest it to configure a mere project or for other users.
- **Configure/improve any project (anyone)**: `AGENT-PROJECT-SETUP.md` → executes
  `global/skills/setup-project/SKILL.md`.
- **Refresh curated knowledge**: `/refresh-knowledge` (recipes/references vs current docs).

## Editing rules for this repo

- Plugins are edited HERE under `plugins/`, never in `~/.claude/`. Any plugin change bumps
  `version` in BOTH `.claude-plugin/marketplace.json` (that entry) and the plugin's own
  `.claude-plugin/plugin.json`, then validate & republish:
  `claude plugin validate ./plugins/<name> --strict && claude plugin marketplace update dev-plugins && claude plugin update <name>@dev-plugins`.
  CI re-checks JSON, version parity + `enabledPlugins` sync, schemas, language anchors and
  PowerShell lint on push (`validate.yml`); installer changes also trigger the
  real-execution smoke matrix (`installer-smoke.yml`, Linux + Windows PowerShell 5.1).
- Global config lives in `global/` and reaches `~/.claude/` only via `install.sh`.
- Subagent model is pinned by `env.CLAUDE_CODE_SUBAGENT_MODEL` (Sonnet) in
  `global/settings.json`, which overrides any agent's `model:` frontmatter. Keep
  `global/agents/*.md` in sync — `scripts/check-subagent-model.sh` enforces it in CI.
- Token discipline: skill bodies and `references/` load on demand — keep descriptions sharp
  and short; CLAUDE.md-style content stays within the budgets defined in
  `global/skills/setup-project/SKILL.md`.
- All config content in English; README stays in Spanish. `secrets.env` is never committed.
