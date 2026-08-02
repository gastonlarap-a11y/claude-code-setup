# claude-code-setup

Portable Claude Code configuration, the `dev-plugins` marketplace, and a protocol that
configures AI coding agents in any project (Claude Code natively; Codex/Cursor read the
generated `AGENTS.md` directly, and so does Antigravity CLI). Agent entry points:

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
  CI re-checks JSON, version parity + `enabledPlugins` sync, forgotten version bumps
  (feature branches), schemas, language anchors, PowerShell lint, template-skeleton
  validity and secret scanning (gitleaks) on push (`validate.yml`); installer changes
  also trigger the real-execution smoke matrix (`installer-smoke.yml`, Linux + Windows
  PowerShell 5.1).
- Global config lives in `global/` and reaches `~/.claude/` only via `install.sh`.
- Token discipline: skill bodies and `references/` load on demand — keep descriptions sharp
  and short; CLAUDE.md-style content stays within the budgets defined in
  `global/skills/setup-project/SKILL.md`.
- All config content in English; README stays in Spanish. `secrets.env` is never committed.
- Secrets: `secrets.env` only feeds the installer's user-scope MCP registrations
  (`global/mcp-servers.json`, data-driven). A future plugin-scoped secret uses
  `userConfig` with `sensitive: true` in its `plugin.json` (stored in the OS keychain,
  prompted at enable time) — never a new bespoke installer path. Hooks consume it via
  exec form + the `CLAUDE_PLUGIN_OPTION_<KEY>` env var; `${user_config.*}` is rejected
  in shell-form hook commands (2.1.207 security fix).
- Repo-level changes (installers, `global/`, CI, protocols) get a `CHANGELOG.md` entry
  under `[Unreleased]`; per-plugin changes rely on the dual-bump rule instead.

## Engineering standards

- Before declaring work done, run the CI checks locally and report real results — the
  `verify` skill runs the full `validate.yml` mirror (check scripts, shellcheck, plugin
  schema validation).
- Error contract: hooks and statusline scripts are fail-open (degrade silently, never
  break a session); installers and CI scripts fail loud. Keep new scripts on the right side.
- No speculative abstractions: a new installer path, script or config knob needs a problem
  this repo already has — say which and why.
- Ambiguous request → ask targeted questions first; a better route exists → say why and
  let the requester choose before proceeding.
