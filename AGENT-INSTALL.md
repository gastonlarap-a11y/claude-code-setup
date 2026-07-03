# AGENT-INSTALL — Restore instructions for an AI agent

You are restoring Gastón's Claude Code global configuration on a fresh machine from this
directory. Follow these steps in order. Do not skip verification.

## 1. Preconditions
- Confirm the `claude` CLI is installed (`claude --version`) and is **≥ 2.1.154** (tested with 2.1.199)
  (needed for `defaultEnabled: false` in marketplaces; older versions are handled by a
  fallback in `install.sh` but should be upgraded). If missing, install it
  (`npm install -g @anthropic-ai/claude-code`) and ask the user to log in (`claude` → follow auth).
- Confirm `jq` is installed — the statusline degrades without it. Install: `brew install jq`
  (macOS) / `winget install --id jqlang.jq -e` (Windows) / `sudo apt install jq` (Linux).
- Confirm some Python is available (`python3`, `python` or `py` — any ≥3.8): `install.sh`
  and the hooks use it as the JSON fallback when `jq` is missing.
- Confirm `secrets.env` exists here. If not, copy `secrets.env.example` to `secrets.env`
  and ask the user for the real values before continuing.
- Dart SDK ≥ 3.9 is only needed inside Flutter projects (for the bundled Dart MCP/LSP);
  do not install it globally as part of this restore.

### Windows
`install.sh` is bash — PowerShell/CMD cannot run it. Install Git for Windows
(`winget install --id Git.Git -e`) and run EVERYTHING below from **Git Bash**
(WSL also works, but then `~/.claude` lives inside the distro, not in Windows).
Path notes for Git Bash: `C:\Users\<user>\...` is written `/c/Users/<user>/...`,
and `~` resolves to the Windows user home, so the config lands in
`C:\Users\<user>\.claude`. Install `jq` with `winget install --id jqlang.jq -e`.

## 2. Restore
Run:

```bash
bash install.sh
```

This does, idempotently:
1. Copies `global/CLAUDE.md`, `global/settings.json`, `global/skills/`, `global/agents/`,
   `global/hooks/`, `global/rules/` and `global/statusline.sh` into `~/.claude/` and marks
   scripts executable.
2. Sources `secrets.env` and writes the keys into the `env` block of
   `~/.claude/settings.local.json` (machine-local, never committed anywhere).
3. Registers the `context7` MCP server at user scope (`claude mcp add-json`), whose config
   references `${CONTEXT7_API_KEY}` — resolved from the env block above.
4. Registers this repo as the `gaston-plugins` marketplace
   (`claude plugin marketplace add <this repo>`).
5. Installs the plugins listed in `plugins.txt` (official LSPs + expo + the 6 stack
   plugins + the 5 domain plugins: api-design, bots, realtime, background-jobs, ux), then
   force-disables everything except the LSPs at user scope. LSP plugins stay globally
   enabled via `global/settings.json`.

If `install.sh` fails at any step, perform that step manually (the script is short — read it).

## 3. Verify
- `claude mcp list` shows `context7` connected.
- `claude plugin marketplace list` shows `gaston-plugins`.
- `claude plugin list` shows the 3 LSP plugins **enabled**, and `expo` + the 11 personal
  plugins (`nestjs`, `go`, `android-kotlin`, `react-nextjs`, `flutter`, `react-native`,
  `api-design`, `bots`, `realtime`, `background-jobs`, `ux`) **installed but disabled**.
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
  (browser e2e), `code-review@claude-plugins-official`.
- Per-project config: each repo under `~/Documents/Git/` carries its own `CLAUDE.md` +
  `.claude/` in git; nothing to restore from here.

## Notes
- Commits in this repo (and everywhere): NO `Co-Authored-By` trailers, no AI attribution.
- All config files stay in English; conversation with the user is in Spanish. Research and
  doc lookups are done in English against the latest stable, official sources.
