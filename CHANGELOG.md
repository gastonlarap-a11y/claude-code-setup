# Changelog

Repo-level changes: installers, `global/` config, CI, protocols and cross-marketplace
behavior. Individual plugins keep their own `version` in
`plugins/<name>/.claude-plugin/plugin.json` (dual-bump rule); they appear here only when
a change affects the marketplace as a whole.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · dates YYYY-MM-DD.

## [Unreleased]

### Added
- Multi-agent bridges in `setup-project` (opt-in via batched question): shared
  `.agents/skills` symlink, `.gemini/settings.json` context bridge, project-scope
  `.codex/config.toml` / `.codex/hooks.json` skeletons (templates § Other-agent bridges),
  plus expanded discovery of other-agent config (`GEMINI.md`, `.gemini/`, `.codex/`,
  `.agents/skills/`, `AGENTS.override.md`, `.clinerules`).
- MCP/plugin offers by signal in `setup-project` (GitHub MCP, playwright,
  security-guidance) and a third-party due-diligence checklist (official vs community
  risk tiers).
- Global hooks: `guard-git-add-all.sh` (denies bulk staging), `audit-config-change.sh`
  (ConfigChange audit trail in `~/.claude/config-audit.log`), `notify-os.sh` (OS
  notifications, opt-in, unwired by default).
- Secret scanning in CI (`gitleaks/gitleaks-action@v3`) and in the `ci-cd` skill's
  conventions.
- CI gates: `check-plugin-version-bump.sh` (feature branches: a plugin change without its
  version bump fails) and `check-templates.sh` (setup-project skeletons must stay valid
  JSON/TOML, nested-fence aware).
- Installer preview flag: `install.sh --dry-run` / `install.ps1 -DryRun` (+ smoke run 6).
- `LICENSE` (MIT) and this `CHANGELOG.md`.

### Changed
- Repo root instructions split for dogfooding: canonical `AGENTS.md` + thin `CLAUDE.md`
  (`@AGENTS.md` import + Claude-specific delta).
- Installers: MCP secret injection is now data-driven from `global/mcp-servers.json` —
  adding a keyed server needs zero installer code.
- `global/settings.json`: deny `Edit(.git/**)` + dependency lockfiles; wired the
  guard-git-add-all and audit-config-change hooks.
- Docs accuracy: Gemini CLI does not read `AGENTS.md` natively (bridge documented);
  Gemini CLI individual-tier sunset noted (successor: Antigravity CLI); MCP tool-search
  novelty added; README sync snippet uses targeted staging (`git add global`).

### Deferred
- Windows-native (`.ps1`) ports of the bash hooks/statusline — next batch.
