# AGENT-INSTALL — Restore instructions for an AI agent

You are restoring the owner's Claude Code global configuration on a fresh machine from
this directory. Follow these steps in order. Do not skip verification.

## 1. Preconditions
- Confirm the `claude` CLI is installed (`claude --version`) and is **≥ 2.1.187** (tested with 2.1.201)
  (2.1.154 honors `defaultEnabled: false`; 2.1.187 adds `sandbox.credentials`, which
  `global/settings.json` uses). If missing, install it with the native installer
  (`curl -fsSL https://claude.ai/install.sh | bash`; Windows PowerShell:
  `irm https://claude.ai/install.ps1 | iex`) and ask the user to log in (`claude` → follow auth).
- Confirm `jq` is installed — the statusline degrades without it. Install: `brew install jq`
  (macOS) / `winget install --id jqlang.jq -e` (Windows) / `sudo apt install jq` (Linux).
- Confirm some Python is available (`python3`, `python` or `py` — any ≥3.8): `install.sh`
  and the hooks use it as the JSON fallback when `jq` is missing.
- Confirm `secrets.env` exists here. If not: read `secrets.env.example`, interview the
  user one variable at a time (what it is for, expected format), then write `secrets.env`
  yourself with the answers before continuing. Never echo the values back or commit them.
- Dart SDK ≥ 3.9 is only needed inside Flutter projects (for the bundled Dart MCP/LSP);
  do not install it globally as part of this restore.

### Windows
Two routes (running Claude Code itself needs neither Git Bash nor WSL since 2.1.120):
- **Native (recommended on company machines)**: run `.\install.ps1` from PowerShell —
  same actions as `install.sh`, no bash needed. Note: the hooks and statusline are bash
  scripts; without Git for Windows they stay inert (everything else works). Sandboxing
  is not supported on native Windows — the startup warning is expected.
- **Git Bash / WSL2**: install Git for Windows (`winget install --id Git.Git -e`) and run
  `bash install.sh` from Git Bash (WSL also works, but then `~/.claude` lives inside the
  distro, not in Windows). Git Bash paths: `C:\Users\<user>\...` is `/c/Users/<user>/...`;
  config lands in `C:\Users\<user>\.claude`.

Install `jq` with `winget install --id jqlang.jq -e`.

## 2. Restore
Run:

```bash
bash install.sh        # native Windows: .\install.ps1 from PowerShell
                       # preview without writing: bash install.sh --dry-run  /  .\install.ps1 -DryRun
```

Response language: pass `CLAUDE_LANGUAGE=<language>` (default `spanish`) — the installer
applies it to the copied `settings.json` (`"language"`) and `CLAUDE.md` (Language section)
and persists it in `~/.claude/.install-profile`, so re-runs without the variable keep the
choice. The repo sources always stay Spanish-default; the anchor literals live in
`scripts/language-anchors.env` (asserted by CI).

This does, idempotently:
1. Backs up the exact items it is about to replace into `~/.claude/.backup-<timestamp>/`
   (last 3 backups kept — see "Rollback & uninstall" below).
2. Copies `global/CLAUDE.md`, `global/settings.json`, `global/skills/`, `global/agents/`,
   `global/hooks/`, `global/rules/` and `global/statusline.sh` into `~/.claude/` and marks
   scripts executable.
3. Prunes orphans via `~/.claude/.install-manifest`: files shipped by a previous run but
   no longer in the repo are removed (manifest-listed paths only — user files survive).
4. Applies `CLAUDE_LANGUAGE` (if set or persisted) to the copied `settings.json` and
   `CLAUDE.md` — see "Response language" above.
5. Sources `secrets.env` and resolves, data-driven, every env var declared by the servers
   in `global/mcp-servers.json` (today: `CONTEXT7_API_KEY` for `context7`) directly into
   their user-scope MCP registrations (`~/.claude.json` — machine-local, never committed).
   Missing keys just drop: the server registers keyless (context7: lower rate limits) and
   `/doctor` stays clean. Adding a keyed server = one JSON entry + one `secrets.env` line,
   zero installer changes.
   Note: a user-level `settings.local.json` env block is NOT read by Claude Code — the
   `${VAR}` placeholders in MCP configs expand from the process environment only.
6. (Re-)registers each server (`claude mcp remove` + `add-json`), so key/config updates
   take effect on re-runs.
7. Registers this repo as the `dev-plugins` marketplace
   (`claude plugin marketplace add <this repo>`).
8. Installs the plugins listed in `plugins.txt` (official LSPs + expo + the 7 stack
   plugins + the 5 domain plugins: api-design, bots, realtime, background-jobs, ux).
   Stack/domain plugins install disabled (`defaultEnabled: false` in the manifests +
   explicit `false` entries in `global/settings.json`); LSP plugins stay globally enabled.

If `install.sh` fails at any step, perform that step manually (the script is short — read it).

## 3. Verify
- `claude mcp list` shows `context7` connected.
- `claude plugin marketplace list` shows `dev-plugins`.
- `claude plugin list` shows the 4 LSP plugins **enabled**, and `expo` + the 12 personal
  plugins (`nestjs`, `go`, `android-kotlin`, `react-nextjs`, `flutter`, `react-native`,
  `dotnet`, `api-design`, `bots`, `realtime`, `background-jobs`, `ux`) **installed but
  disabled**.
- `/research <question>` works in a session (runs in the `docs-researcher` subagent and
  returns version + snippet + source).
- `/setup-project` is listed in the `/` menu (global skill that creates/audits per-project
  config).
- Start a session in `$HOME` and run `/context`: the global `CLAUDE.md` must be loaded and
  NO stack-plugin skills must appear (they are per-project).
- The statusline shows model, directory and a context-usage bar.
- Edit a scratch `.go` file: the `format-on-edit.sh` PostToolUse hook must gofmt it, and
  `global/rules/go.md` should load (path-scoped rule).
- Ask to read a `.env` file: it must be denied by permissions.
- `/doctor` reports no configuration issues. `/sandbox` shows the resolved sandbox config
  (macOS/Linux/WSL2; on native Windows a "sandbox unavailable" warning is expected).
- In a scratch repo on `main`, asking for `git push` must be denied by `guard-git-push.sh`;
  on a feature branch it goes through.
- Asking for `git add -A` (any repo) must be denied by `guard-git-add-all.sh`; staging
  specific paths goes through.
- Editing `~/.claude/settings.json` from OUTSIDE the session while one runs must append a
  line to `~/.claude/config-audit.log` (ConfigChange audit hook).

## 4. Per-project configuration (tell the user)
The primary flow is `/setup-project` inside each repo (new, legacy, or already configured):
it detects the stack, audits/preserves any existing AI config, enables the right plugins,
and generates token-lean local config (protocol: `global/skills/setup-project/SKILL.md`).

Manual alternative — stack plugins via the project's `.claude/settings.json`:

```json
{ "enabledPlugins": { "nestjs@dev-plugins": true } }
```

React Native projects co-enable the official Expo plugin:

```json
{
  "enabledPlugins": {
    "react-native@dev-plugins": true,
    "expo@claude-plugins-official": true
  }
}
```

CLI alternative inside the project: `claude plugin enable <name>@dev-plugins --scope project`.
The template repos under `~/Documents/Git/` should carry these snippets in git (see README
for the per-template table).

To configure a project for someone who is NOT restoring this whole setup (shared directory,
teammate's machine): follow `AGENT-PROJECT-SETUP.md` instead of this file.

## 5. Optional extras (ask the user)
- VCS CLIs: `gh` (GitHub) and/or `az` with the `azure-devops` extension (Azure DevOps),
  depending on which remotes this machine will use. The global CLAUDE.md tells agents to
  install the missing one or pause with instructions.
- Optional official plugins, not installed by default: `playwright@claude-plugins-official`
  (browser e2e), `code-review@claude-plugins-official`, `security-guidance@claude-plugins-official`
  (reviews Claude's changes for vulnerabilities as it works).
- Per-project config: each repo under `~/Documents/Git/` carries its own `CLAUDE.md` +
  `.claude/` in git; nothing to restore from here.

## Rollback & uninstall

- Every run first snapshots the files it replaces into `~/.claude/.backup-<timestamp>/`
  (last 3 kept). Rollback: `cp -R ~/.claude/.backup-<ts>/. ~/.claude/` and open a new
  session.
- Machine-local installer state: `~/.claude/.install-profile` (language) and
  `~/.claude/.install-manifest` (copied-file list used to prune renamed/removed items).
- Uninstall: delete the paths listed in `~/.claude/.install-manifest` plus the
  `.install-*` and `.backup-*` entries; then `claude plugin marketplace remove
  dev-plugins`, uninstall the `plugins.txt` plugins, and remove each server declared in
  `global/mcp-servers.json` (`claude mcp remove <name> --scope user`). Anything not in the
  manifest was not created by the installer — leave it.

## Notes
- Commits in this repo (and everywhere): NO `Co-Authored-By` trailers, no AI attribution.
- All config files stay in English; conversation with the user is in their configured
  language (Spanish by default — see `CLAUDE_LANGUAGE` in section 2). Research and
  doc lookups are done in English against the latest stable, official sources.
