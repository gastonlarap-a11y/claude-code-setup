# AGENT-INSTALL — Restore instructions for an AI agent

You are restoring Gastón's Claude Code global configuration on a fresh machine from this
directory. Follow these steps in order. Do not skip verification.

## 1. Preconditions
- Confirm the `claude` CLI is installed (`claude --version`). If missing, install it
  (`npm install -g @anthropic-ai/claude-code`) and ask the user to log in (`claude` → follow auth).
- Confirm `secrets.env` exists here. If not, copy `secrets.env.example` to `secrets.env`
  and ask the user for the real values before continuing.

## 2. Restore
Run:

```bash
bash install.sh
```

This does, idempotently:
1. Copies `global/CLAUDE.md`, `global/settings.json`, `global/skills/`, `global/agents/`,
   `global/hooks/` into `~/.claude/` and marks hook scripts executable.
2. Sources `secrets.env` and writes the keys into the `env` block of
   `~/.claude/settings.local.json` (machine-local, never committed anywhere).
3. Registers the `context7` MCP server at user scope (`claude mcp add-json`), whose config
   references `${CONTEXT7_API_KEY}` — resolved from the env block above.
4. Installs the plugins listed in `plugins.txt` from the official marketplace.

If `install.sh` fails at any step, perform that step manually (the script is short — read it).

## 3. Verify
- `claude mcp list` shows `context7` connected.
- `claude plugin list` (or `/plugin` inside a session) shows `typescript-lsp`, `gopls-lsp`, `kotlin-lsp`.
- Start a session in `$HOME` and run `/context`: the global `CLAUDE.md` must be loaded.
- Run `/skills` or ask something about Kubernetes: the `docker-kubernetes` skill should be available.
- Edit a scratch `.go` file: the `format-on-edit.sh` PostToolUse hook must gofmt it.

## 4. Optional extras (ask the user)
- GitHub MCP: the user previously had the GitHub MCP connected via claude.ai connectors;
  reconnect it from the UI if desired, or rely on the `gh` CLI (preferred for simple ops).
- Per-project config: each repo under `~/Documents/Git/` carries its own `CLAUDE.md` +
  `.claude/` in git; nothing to restore from here.

## Notes
- Commits in this repo (and everywhere): NO `Co-Authored-By` trailers, no AI attribution.
- All config files stay in English; conversation with the user is in Spanish.
