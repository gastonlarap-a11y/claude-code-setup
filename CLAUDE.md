# claude-code-setup

Portable Claude Code configuration and the `gaston-plugins` marketplace. Agent entry points:

- **Restore a machine (owner only)**: `AGENT-INSTALL.md` → runs `install.sh`, which
  OVERWRITES `~/.claude/`. Never suggest it to configure a mere project or for other users.
- **Configure/improve any project (anyone)**: `AGENT-PROJECT-SETUP.md` → executes
  `global/skills/setup-project/SKILL.md`.
- **Refresh curated knowledge**: `/refresh-knowledge` (recipes/references vs current docs).

## Editing rules for this repo

- Plugins are edited HERE under `plugins/`, never in `~/.claude/`. Any plugin change bumps
  `version` in BOTH `.claude-plugin/marketplace.json` (that entry) and the plugin's own
  `.claude-plugin/plugin.json`, then republish:
  `claude plugin marketplace update gaston-plugins && claude plugin update <name>@gaston-plugins`.
- Global config lives in `global/` and reaches `~/.claude/` only via `install.sh`.
- Token discipline: skill bodies and `references/` load on demand — keep descriptions sharp
  and short; CLAUDE.md-style content stays within the budgets defined in
  `global/skills/setup-project/SKILL.md`.
- All config content in English; README stays in Spanish. `secrets.env` is never committed.
