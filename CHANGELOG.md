# Changelog

Repo-level changes: installers, `global/` config, CI, protocols and cross-marketplace
behavior. Individual plugins keep their own `version` in
`plugins/<name>/.claude-plugin/plugin.json` (dual-bump rule); they appear here only when
a change affects the marketplace as a whole.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · dates YYYY-MM-DD.

## [Unreleased]

### Added
- `verify-turn` hook (`Stop`; `.sh` + `.ps1`): the end-of-turn quality gate. Every other guard
  here checks the config or the command — this one checks the **work**. It runs the project's
  own cheap checks as the turn closes and refuses to let it end if one fails, handing the
  failure back while the context is still alive. Until now "run lint/typecheck before declaring
  work done" was prose in `global/CLAUDE.md`: a guide the model had to remember, where a
  deterministic sensor belonged. Generic by design — each repo declares its own verified
  commands in `.claude/settings.json`. Handles the three known traps: `stop_hook_active` so a
  failure cannot loop, JSON `decision: block` (exit 1 is silently ignored by the harness), and a
  bounded `timeout`. Fail-open like the rest.
- `setup-project` now offers the gate for every project with a typecheck or lint that runs in
  seconds **and passes today** — wiring it onto an already-red check would block every turn from
  the start.

### Added
- `guard-shell-edit` hook (`PreToolUse`, Bash; `.sh` + `.ps1`): denies shell writes to source
  files inside the repo — `pathlib.write_text`, `open(…,'w')`, `sed -i`, `tee`, redirections
  into source extensions — and instructs the model to use Edit/Write. Generated and temp paths
  (`dist`, `build`, `bin`, `obj`, `node_modules`, `$TMPDIR`, `/tmp`) pass; fail-open.
  Motivated by a measured session where 229 of 932 Bash commands rewrote whole React/C# files
  through Python heredocs instead of Edit, against only 245 Edit calls.
- `scripts/check-context-budget.sh` + `validate.yml` step: hard ceiling on always-loaded
  instructions (`global/CLAUDE.md` ≤ 45 lines, warn at 40; each `global/rules/*.md` ≤ 40).
  Deterministic guard against Context Bloat, the smell found in 42% of real repos.
- `post-merge-cleanup` skill: the merge-verification + prune + fresh-branch procedure extracted
  out of the always-loaded `global/CLAUDE.md`.
- `references/confidence-rubric.md` for `setup-project`: how to score the `Confianza: NN%` line
  the global instructions now require, with per-cause deductions and calibration floors.
- `harness` skill + `show.sh`: a catalogue of everything the configuration provides — skills and
  what each is for, guards, per-language rules, plugins, and what carries over to other agents.
  Generated from the installed files rather than hand-written, so it cannot go stale; takes an
  optional term to filter. Runs standalone in any terminal, which is also how a local LLM or a
  non-Claude agent consumes it.
- `hooks/lib/agent-io.sh`: shared hook I/O so one guard script serves three CLIs. Claude Code
  and Codex share a contract field for field; Antigravity reads `.toolCall.args.CommandLine` and
  answers `{"decision": …}`. The dialect lives in this one file.
- `install.sh` registers the guards for Codex (`~/.codex/hooks.json`) and Antigravity
  (`~/.gemini/config/hooks.json`) — only when those config dirs already exist, merging with `jq`
  so hooks from other tools survive, and idempotent across re-runs.
- `github-new-repo` skill, rescued from `~/.claude/skills/` where it lived unversioned.

### Fixed
- `guard-git-push` and `guard-git-add-all` (`.sh` + `.ps1`) read past the end of the command
  line they were analysing. `sed 's/[;&|].*$//'` cuts per line, so in a multi-line command the
  segment bled into the following lines — `git push -u origin feat/x` followed by
  `gh pr create --base main` on the next line parsed `main` as a refspec and denied a perfectly
  legal push. Both now stop at the end of the line first. Verified with 8 cases: explicit
  pushes to main/master and bulk staging still denied, feature-branch pushes and multi-line
  commands allowed.
- `post-merge-cleanup` split `git branch -D` onto its own line, so a failed `git pull` — no
  network, a conflict, a wrong remote — still deleted the local branch and left the commits
  only on the remote. It happened in practice. The whole cleanup is now one `&&` chain, and the
  skill states that a successful `pull` is the second load-bearing condition alongside the
  merge verification, not a formality.
- Gemini CLI retired on 2026-06-18; its successor Antigravity CLI reads `AGENTS.md` natively and
  uses `.agents/skills/`. `setup-project` no longer offers or generates the `.gemini/settings.json`
  bridge (a legacy `GEMINI.md`/`.gemini/` found in a repo is still merged and left alone), and the
  other-agent question now asks about Codex and Antigravity.

### Changed
- `global/CLAUDE.md`: 44 → 36 lines while gaining three rules — tool-for-the-job (Read/Grep/Edit
  vs Bash), the scope contract for tasks touching 3+ files, and the confidence line. Removed
  what a deterministic mechanism already guarantees: the `git push`/force-push and secrets
  prose (covered by `guard-git-push.sh`, `guard-git-add-all.sh` and `permissions.deny`), the
  skill-routing bullets (covered by each skill's `description`), and the post-merge procedure
  (now a skill).
- `global/settings.json`: `Read`, `Edit`, `Write` and `MultiEdit` added to `permissions.allow`.
  Bash had 50 pre-approved entries and the editing tools none, which made the shell the cheapest
  path and produced the rewrite-by-heredoc pattern above. The `deny` list keeps precedence, so
  `.env*`, `secrets.env`, `.git/**`, lockfiles and keys stay protected.
- `format-on-edit` (`.sh` + `.ps1`): stop probing `dotnet csharpier` when it is not installed —
  it cost ~0.1 s per `.cs` edit and always failed on repos that format via `.editorconfig` +
  analyzers with `EnforceCodeStyleInBuild`.
- `setup-project` templates: the `new-<unit>` skeleton now settles the contract first, fans the
  independent branches out in parallel for units touching 6+ files, and keeps magnet files
  (DI registration, i18n dictionary, shared types, route tables) on the main thread.
- `install.ps1` wires the new hook to its PowerShell port on Windows without Git Bash.
- **Nothing is enabled globally any more**: the four official LSP plugins moved to `false` in
  `global/settings.json`, joining the 13 stack plugins. A language server loaded in a project of
  another language is pure context cost. Every plugin, LSP included, is enabled per project in
  its `.claude/settings.json`; `setup-project` maps stack → plugins and states this explicitly.
  The rule is now written down in `global/CLAUDE.md`, where it did not exist. `install.sh`
  re-applies the `enabledPlugins` block after installing, because `claude plugin install` turns
  a plugin on unless its manifest sets `defaultEnabled: false` — which the official LSP and
  expo plugins do not, so they silently came back on after every install.
- `global/settings.json` `model` → `opus[1m]`, matching what the machine actually runs, so a
  re-install stops reverting it.

## [1.0.0] - 2026-07-24

### Added
- Strict network allowlist for sandboxed commands (`sandbox.network.strictAllowlist`,
  CLI ≥ 2.1.219): egress limited to package registries (npm, Go proxy, pub.dev, Maven,
  NuGet) and GitHub; older CLIs ignore the key and fall back to permission prompts.
  Version floor in `START.md`/`AGENT-INSTALL.md` raised accordingly.
- `setup-project` discovery now also covers `.windsurf/rules/` and `.devin/rules/`, and
  notes `/init` + `CLAUDE_CODE_NEW_INIT=1` as the quick-bootstrap alternative it supersedes.
- `new-plugin` skill documents the marketplace `renames` map (safe plugin rename/retire,
  CLI ≥ 2.1.193).
- Own-repo agent config via `/setup-project` (dogfood): tracked `.claude/settings.json`
  (routine-command allows, secrets read-deny), `verify` and `new-plugin` project skills,
  engineering-standards block in `AGENTS.md`, config-maintenance block in `CLAUDE.md`,
  other-agent bridges (`.agents/skills`, `.gemini/settings.json`, `.codex/config.toml`)
  and local-config entries in `.gitignore`.
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
- Windows-native PowerShell ports of every hook and the statusline
  (`global/hooks/*.ps1`, `global/statusline.ps1`): same stdin/stdout JSON contract,
  fail-open, pure-ASCII sources (PS 5.1-safe). `install.ps1` wires them automatically
  when bash is absent (test override: `CLAUDE_FORCE_PS_HOOKS=1`); smoke run 8 exercises
  the rewrite and executes a port for real.
- `LICENSE` (MIT) and this `CHANGELOG.md`.

### Removed
- context7 MCP server (user decision: no freemium services in the config): the
  `research` skill and the `docs-researcher` agent now work exclusively against official
  docs on the web (WebSearch/WebFetch — previously the fallback). The data-driven
  MCP+secrets installer mechanism stays, empty, for future servers.

### Changed
- `fallbackModel` updated to `["claude-opus-5", "claude-sonnet-5"]` (Opus 5 is the Claude
  Code default since 2.1.219; `claude-opus-4-8` remains the Bedrock/Vertex lineage).
- Docs: README documents the primary model (`fable`) and the Claude 5 lineup, and the
  `global/rules/` row now lists `csharp`; `AGENTS.md` secrets note records that
  `${user_config.*}` is rejected in shell-form hooks (use exec form +
  `CLAUDE_PLUGIN_OPTION_<KEY>`, 2.1.207 security fix).
- `setup-project` now ALWAYS asks which agent CLIs to configure (Codex CLI / Gemini CLI /
  none) in the batched questions — repo signs only pre-fill the suggested answer; bridges
  still require the explicit per-agent choice.
- Repo root instructions split for dogfooding: canonical `AGENTS.md` + thin `CLAUDE.md`
  (`@AGENTS.md` import + Claude-specific delta).
- Installers: MCP secret injection is now data-driven from `global/mcp-servers.json` —
  adding a keyed server needs zero installer code.
- `global/settings.json`: deny `Edit(.git/**)` + dependency lockfiles; wired the
  guard-git-add-all and audit-config-change hooks.
- Docs accuracy: Gemini CLI does not read `AGENTS.md` natively (bridge documented);
  Gemini CLI individual-tier sunset noted (successor: Antigravity CLI); MCP tool-search
  novelty added; README sync snippet uses targeted staging (`git add global`).
- README: new "Comandos y skills disponibles" reference — every invokable command
  (manual/auto skills, plugin skills, installer flags, validation scripts, plugin flow)
  with what it does and when to use it; Windows inert-hooks caveats replaced by the
  native-ports wiring across README/START/AGENT-INSTALL.