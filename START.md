# START — Interactive bootstrap for an AI agent

You are an AI agent. The user pointed you at this file to configure Claude Code using
this directory as a toolbox — on any machine, for the global setup, for a project, or
both. Interview the user only for what you cannot detect, one question at a time, in
the user's language. Never write anything before the route is confirmed.

## Phase 0 — Detect (run first, ask nothing yet)

Gather silently:

- **OS and shell**: platform, and on Windows whether you are in Git Bash, WSL, or
  PowerShell/CMD (`echo $SHELL` / `$PSVersionTable` behavior tells you).
- **Claude CLI**: `claude --version` (needs ≥ 2.1.187; install with the native installer:
  `curl -fsSL https://claude.ai/install.sh | bash` on macOS/Linux/WSL,
  `irm https://claude.ai/install.ps1 | iex` on Windows PowerShell).
- **Existing global config**: if `~/.claude/` exists, inventory it read-only — which of
  `CLAUDE.md`/`settings.json` are present, file counts under `skills/`, `agents/`,
  `hooks/`, `rules/`, and whether they differ from this repo's `global/` (`diff -rq`).
  This feeds the Phase 2 overwrite summary.
- **Other AI assistants**: machine-level config such as `~/.codex/`, `~/.cursor/`,
  `~/.gemini/`, `~/.agents/` (cross-agent skills dir), or a global `AGENTS.md` — report
  what exists; never touch it. Note: Gemini CLI stopped serving individual accounts on
  2026-06-18 (successor: the closed-source Antigravity CLI), so `~/.gemini/` may be a
  leftover — still report it.
- **Secrets**: does `secrets.env` exist in this directory?
- **Marketplace**: `claude plugin marketplace list` — is `dev-plugins` registered?
- **Current directory**: are you inside this toolbox repo, or inside a target project?

Windows: running Claude Code needs no Git Bash (since 2.1.120 it falls back to the
PowerShell tool). For a global restore there are two routes: `install.ps1` natively from
PowerShell, or `install.sh` from Git Bash/WSL2. Hooks and statusline have native
PowerShell ports — without bash, `install.ps1` wires the installed settings to the
`.ps1` variants automatically. `jq`: `winget install --id jqlang.jq -e` (optional on
native Windows — the `.ps1` ports parse JSON natively). Project-only configuration needs
none of this — skip the requirement for that route.

## Phase 1 — Interview (only the gaps)

Ask in order, skipping anything Phase 0 already answered:

1. **Who are you?** The owner of this setup, or someone else using it as a toolbox?
   This decides whether `~/.claude` may be touched at all.
2. **What do you want configured?** (a) this machine's global setup, (b) one or more
   projects, (c) both.
3. **Owner + global only** — is this a personal machine or a company/restricted one?
   - No `secrets.env` and the user HAS the values: read `secrets.env.example`, ask for each
     variable one at a time, and write `secrets.env` yourself before running the installer.
   - Company machine without the values: offer to install WITHOUT secrets — everything
     works except the context7 MCP key (research falls back to web) — and say so upfront.
   - Company machine with policy restrictions (no global npm, proxy, no winget): surface
     the blockers found in Phase 0 and agree on workarounds before proceeding.
4. **Owner + global only** — preferred response language? Default: keep Spanish. Any other
   answer: run the installer with `CLAUDE_LANGUAGE=<language>` (e.g. `english`) — it
   rewrites the installed copies and persists machine-locally, so plain re-runs keep it.
5. **Projects** — which one(s)? Ask for the path(s) if you are not already inside one.
   Stack detection is NOT your job here; the project protocol handles it.

## Phase 2 — Route (confirm, then execute)

State the chosen route in one short summary and get a yes before executing. For
owner + global, the summary MUST list what the Phase 0 inventory found that will be
overwritten, and note that the installer first snapshots those exact items to
`~/.claude/.backup-<timestamp>/` (last 3 kept — see AGENT-INSTALL.md "Rollback & uninstall").

| Who | Scope | Do this |
|---|---|---|
| Owner | Global | Follow `AGENT-INSTALL.md` (runs `install.sh`; on native Windows, `install.ps1` from PowerShell). No `secrets.env`: interview the user per variable from `secrets.env.example` and write the file yourself; user lacks the values → run anyway and report the WARNING as expected. |
| Owner | Project(s) | Global first if this machine never had it (plugins live at user scope). Then, per project: follow `AGENT-PROJECT-SETUP.md` → run the `setup-project` protocol inside that repo. |
| Someone else | Project(s) | Follow `AGENT-PROJECT-SETUP.md` only. Optionally register the marketplace (`claude plugin marketplace add <this directory>`). |
| Someone else | Global | **Refuse the restore** — `install.sh` overwrites `~/.claude` with the owner's personal identity, language and git rules. Offer instead: marketplace registration + per-project setup, and point them to `global/` as reference material for building their own. |

Both scopes requested: global first, then each project.

## Phase 3 — Verify (per what was installed)

- Global: run the checklist in `AGENT-INSTALL.md` section 3 (MCP connected, marketplace
  listed, plugins installed-but-disabled, `/context` clean in `$HOME`, statusline, hooks,
  `.env` read denied). Without secrets, context7 shows disconnected — expected; note it.
- Per project: the `setup-project` protocol carries its own verification (step 5); make
  sure it ran, including the fresh-session `/context` check.
- Report in the user's language: what was configured, what was skipped and why, and the
  exact next command for anything deferred (e.g. adding the context7 key later:
  put it in `secrets.env` and re-run `bash install.sh` — it is idempotent).

## Hard rules

- Never run `install.sh` for anyone but the owner. Never touch a third party's
  `~/.claude`.
- Nothing is executed before the user confirms the route summary.
- One question at a time; detected facts are stated, not asked.
- Conversation in the user's language; everything you write to disk stays in English.
