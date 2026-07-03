# START — Interactive bootstrap for an AI agent

You are an AI agent. The user pointed you at this file to configure Claude Code using
this directory as a toolbox — on any machine, for the global setup, for a project, or
both. Interview the user only for what you cannot detect, one question at a time, in
the user's language. Never write anything before the route is confirmed.

## Phase 0 — Detect (run first, ask nothing yet)

Gather silently:

- **OS and shell**: platform, and on Windows whether you are in Git Bash, WSL, or
  PowerShell/CMD (`echo $SHELL` / `$PSVersionTable` behavior tells you).
- **Claude CLI**: `claude --version` (needs ≥ 2.1.154; install:
  `npm install -g @anthropic-ai/claude-code`).
- **Existing global config**: does `~/.claude/` exist with a `CLAUDE.md`/`settings.json`?
- **Secrets**: does `secrets.env` exist in this directory?
- **Marketplace**: `claude plugin marketplace list` — is `gaston-plugins` registered?
- **Current directory**: are you inside this toolbox repo, or inside a target project?

Windows + PowerShell/CMD: `install.sh` is bash. Before any global restore, have the
user install Git for Windows (`winget install --id Git.Git -e`) and continue in
**Git Bash** (paths become `/c/Users/<user>/...`; `~/.claude` lands in
`C:\Users\<user>\.claude`). `jq`: `winget install --id jqlang.jq -e`.
Project-only configuration does not need bash — skip this requirement for that route.

## Phase 1 — Interview (only the gaps)

Ask in order, skipping anything Phase 0 already answered:

1. **Who are you?** The owner of this setup (Gastón), or someone else using it as a
   toolbox? This decides whether `~/.claude` may be touched at all.
2. **What do you want configured?** (a) this machine's global setup, (b) one or more
   projects, (c) both.
3. **Owner + global only** — is this a personal machine or a company/restricted one?
   - Company machine without `secrets.env`: offer to install WITHOUT secrets — everything
     works except the context7 MCP key (research falls back to web) — and say so upfront.
   - Company machine with policy restrictions (no global npm, proxy, no winget): surface
     the blockers found in Phase 0 and agree on workarounds before proceeding.
4. **Projects** — which one(s)? Ask for the path(s) if you are not already inside one.
   Stack detection is NOT your job here; the project protocol handles it.

## Phase 2 — Route (confirm, then execute)

State the chosen route in one short summary and get a yes before executing.

| Who | Scope | Do this |
|---|---|---|
| Owner | Global | Follow `AGENT-INSTALL.md` (runs `install.sh`; on Windows, from Git Bash). Without secrets: copy `secrets.env.example` → `secrets.env` only when the user has the real key; otherwise run anyway and report the WARNING as expected. |
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
