# AGENT-INSTALL — Restore instructions for an AI agent

You are restoring Gastón's Claude Code global configuration on a fresh machine from this
directory. Follow these steps in order. Do not skip verification.

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
- Confirm `secrets.env` exists here. If not, copy `secrets.env.example` to `secrets.env`
  and ask the user for the real values before continuing.
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
```

This does, idempotently:
1. Copies `global/CLAUDE.md`, `global/settings.json`, `global/skills/`, `global/agents/`,
   `global/hooks/`, `global/rules/` and `global/statusline.sh` into `~/.claude/` and marks
   scripts executable.
2. Sources `secrets.env` and injects `CONTEXT7_API_KEY` directly into the `context7` MCP
   registration at user scope (`~/.claude.json` — machine-local, never committed). Without
   secrets, context7 registers keyless (lower rate limits) and `/doctor` stays clean.
   Note: a user-level `settings.local.json` env block is NOT read by Claude Code — the
   `${VAR}` placeholders in MCP configs expand from the process environment only.
3. (Re-)registers `context7` (`claude mcp remove` + `add-json`), so key/config updates
   take effect on re-runs.
4. Registers this repo as the `gaston-plugins` marketplace
   (`claude plugin marketplace add <this repo>`).
5. Installs the plugins listed in `plugins.txt` (official LSPs + expo + the 7 stack
   plugins + the 5 domain plugins: api-design, bots, realtime, background-jobs, ux).
   Stack/domain plugins install disabled (`defaultEnabled: false` in the manifests +
   explicit `false` entries in `global/settings.json`); LSP plugins stay globally enabled.

If `install.sh` fails at any step, perform that step manually (the script is short — read it).

## 3. Verify
- `claude mcp list` shows `context7` connected.
- `claude plugin marketplace list` shows `gaston-plugins`.
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

## 4. Per-project configuration (tell the user)
The primary flow is `/setup-project` inside each repo (new, legacy, or already configured):
it detects the stack, audits/preserves any existing AI config, enables the right plugins,
and generates token-lean local config (protocol: `global/skills/setup-project/SKILL.md`).

Manual alternative — stack plugins via the project's `.claude/settings.json`:

```json
{ "enabledPlugins": { "nestjs@gaston-plugins": true } }
```

React Native projects co-enable the official Expo plugin:

```json
{
  "enabledPlugins": {
    "react-native@gaston-plugins": true,
    "expo@claude-plugins-official": true
  }
}
```

CLI alternative inside the project: `claude plugin enable <name>@gaston-plugins --scope project`.
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

## Notes
- Commits in this repo (and everywhere): NO `Co-Authored-By` trailers, no AI attribution.
- All config files stay in English; conversation with the user is in Spanish. Research and
  doc lookups are done in English against the latest stable, official sources.
