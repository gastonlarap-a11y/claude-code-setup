# Skeletons for generated project config

Fill only with verified facts (step 1). Delete any section that would be speculative.
Everything in English. `<angle brackets>` mark what to replace.

## Root AGENTS.md — single-package repo (canonical, cross-agent)

```markdown
# <project-name>

<One sentence: what this is and the stack, e.g. "REST API for X — NestJS 11 (Fastify), Prisma, PostgreSQL.">

## Layout
- `src/<area>/` — <what lives there>
- `test/` — <unit/e2e split>
<max ~6 bullets; only non-obvious locations>

## Commands
- Test: `<verified>`   ·   Single test: `<verified>`
- Lint: `<verified>`   ·   Typecheck: `<verified>`
- Dev: `<verified>`    ·   Migrations: `<verified>`

## Rules
- <hard project rule derived from the codebase, e.g. "route handlers never touch the DB; use src/db repositories">
- <max ~6 bullets; per-language style goes to .claude/rules/, procedures go to .claude/skills/>

## Architecture
- <principle that survived the step-3 selection, stated as a verifiable repo rule naming
  real directories, e.g. "dependency direction is src → libs, never back">
- <max ~6 bullets; delete this section if no principle survived selection>

## Engineering standards
- Every feature ships with its tests. Run <lint> + <typecheck> + <test> before declaring work done; report real results.
- Handle errors explicitly at boundaries; never swallow exceptions or ignored error returns.
- No speculative abstractions: introduce a pattern only for a problem this repo has, and say which and why.
- Ambiguous request → ask targeted questions first. Requested approach wrong or beatable → say why and let the requester choose before proceeding.
```

## Root CLAUDE.md — thin shim (fresh configs)

```markdown
@AGENTS.md

## Config maintenance
<paste the maintenance block from SKILL.md step 6>
```

Existing CLAUDE.md-only project: keep CLAUDE.md canonical — it carries the AGENTS.md
skeleton's content directly (as before) and the split is only offered in step 4.
`AGENTS.md` already present in the repo → same thin CLAUDE.md: `@AGENTS.md` first,
Claude-specific deltas below it — no duplicated content.

## Root AGENTS.md — monorepo (orientation only)

```markdown
# <monorepo-name>

Monorepo (<pnpm workspaces/turborepo/nx/go.work/melos>). Run commands from each package
directory, not the root<adjust if the repo uses root-level task runners>.

- `packages/api` — <stack, one line>
- `packages/web` — <stack, one line>
- `packages/shared` — <one line>

<repo-wide rules only: commit style, cross-package rules. Per-package detail goes in
packages/<name>/CLAUDE.md>

## Engineering standards
<same block as the single-package skeleton — repo-wide, include at root only>
```

The root thin `CLAUDE.md` (shim above) carries the `## Config maintenance` block.
Per-package: same split as the single-package skeleton (AGENTS.md content + thin
CLAUDE.md), minus repo-wide rules.

## README.md (human usage docs)

Not context-loaded — thorough beats terse. Always created for new projects; existing
READMEs are updated non-destructively: merge missing sections, fix commands proven wrong
in step 1, never rewrite the user's prose. Language: match the existing docs; brand-new
projects default to English unless the user chose otherwise. Delete speculative sections.

````markdown
# <project-name>

<One paragraph: what this does, for whom, and the stack.>

## Prerequisites
- <tool + version taken from lockfiles/configs, e.g. "Node 22 (see .nvmrc)">

## Setup
```bash
<install dependencies>
<copy env: cp .env.example .env — list the required variables>
<db setup / migrations — delete if none>
```

## Commands
| Command | What it does |
|---|---|
| `<runner entry>` | <one line> |
<mirror the runner exactly — every entry, nothing else>

## Project structure
- `<dir>/` — <what lives there; only non-obvious directories>

## API documentation
<only if configured: docs URL (e.g. /docs) and how the spec is generated>

## Deployment
<only if known: where it deploys and how>
````

## ARCHITECTURE.md (only when approved in step 4)

Offered only when non-obvious structural decisions need their why recorded; never created
without approval. Not context-loaded — CLAUDE.md/README may point to it. One entry per
non-obvious decision, appended over time.

```markdown
# Architecture

<Chosen structure in one paragraph: what and why, e.g. "Vertical slices under src/features/;
each operation owns handler + types + tests. Chosen because operations are the unit of
change here.">

Rejected: <alternative and the one-line reason it lost>.

## Decisions
- <date> — <decision>: <why, and what was rejected>
```

## Makefile (Go · Flutter single-app · .NET compound workflows, unix-first)

Targets map 1:1 to the verified commands from step 1; delete targets with nothing behind
them. Windows-first .NET teams get `scripts/*.ps1` with the same names instead.

```makefile
.PHONY: run build test lint generate

run:
	<verified dev/run command>
build:
	<verified build command>
test:
	<verified test command>
lint:
	<verified lint command>
generate:
	<verified codegen command>
```

## package.json scripts (Node family)

Standard names: `dev` `build` `test` `test:e2e` `lint` `typecheck` — each mapping to the
verified command. Add the missing ones; never rename existing scripts that work.

## .claude/settings.json

```json
{
  "enabledPlugins": {
    "<stack>@dev-plugins": true
  },
  "permissions": {
    "allow": [
      "Bash(<verified test cmd>:*)",
      "Bash(<verified lint cmd>:*)",
      "Bash(<verified build cmd>:*)"
    ],
    "ask": [
      "Bash(git push *)"
    ],
    "deny": [
      "Read(./**/dist/**)",
      "Read(./**/*.generated.*)",
      "Read(**/.env)",
      "Read(**/.env.*)"
    ]
  }
}
```

Drop `enabledPlugins` when no marketplace is available. Adjust deny globs to the real
generated/vendored paths found in step 1. `ask` fits actions the team wants confirmed,
not banned (deploys, pushes, migrations); drop the block if the user prefers no prompt.

## Hooks (only for guarantees with a deterministic tool behind them)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "if": "Edit(*.<ext>)",
            "command": "jq -r '.tool_input.file_path' | xargs -r <verified formatter cmd>"
          },
          {
            "type": "command",
            "if": "Write(*.<ext>)",
            "command": "jq -r '.tool_input.file_path' | xargs -r <verified formatter cmd>"
          }
        ]
      }
    ]
  }
}
```

The hook command receives the tool-call JSON on stdin — extract `.tool_input.file_path`
with jq, never guess paths. The `if` filter (permission-rule syntax) keeps the hook from
spawning on every edit — scope it to the files the tool actually handles.

## .claude/rules/<topic>.md (path-scoped)

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# <Area> rules
- <convention observed in the codebase, stated so it is verifiable>
- <max ~10 bullets>
```

## .claude/skills/<procedure>/SKILL.md

```markdown
---
name: <procedure>
description: <What it does and when to use it — lead with the words a request would contain.>
disable-model-invocation: true   # keep for side-effectful workflows; drop for pure knowledge
---

# <Procedure title>

1. <step, with the exact commands used in this repo>
2. <step>
3. Run `<verified check>` and report real results.
```

## Standard skill set skeletons (SKILL.md step 3)

Evaluate all four per project. Fill only with commands/paths verified in step 1, or quoted
from roadmap docs — then the skill body says "pending validation" next to the unverified step.

### new-<unit> — scaffold the repeating unit of work

```markdown
---
name: new-<unit>
description: Scaffold a new <unit> under <path> following the <exemplar> pattern. Use when adding a <feature/module/slice>.
argument-hint: "<unit-name>"
---

# New <unit>

1. Create `<path>/<name>/` mirroring `<best existing exemplar dir>`: <the files every unit has>.
2. <register/mount step — exact file and code shape, e.g. wire it in the entry point>
3. <test conventions: runner, file naming, the repo's assertion style>
4. Run <lint> + <typecheck> + <test> and report real results.
```

### verify — prove a change works end-to-end

```markdown
---
name: verify
description: Launch the app and verify a change end-to-end. Use before declaring work done.
---

# Verify

1. Start: `<verified dev/run command>` (background) — ready when <log line / port>.
2. Probe: `<curl/CLI command against the real health or feature endpoint>` → expect <output>.
3. <extra probes worth checking: docs endpoint, main page, …>
4. Stop the dev process; report what was actually observed.
```

Library without a runtime surface: replace 1–3 with the full test suite plus an
example/consumer run.

### deploy — side-effectful, never model-invoked

```markdown
---
name: deploy
description: Deploy/release this project to <target>. User-invoked only.
disable-model-invocation: true
---

# Deploy to <target>

1. <pre-flight: tests/build/migrations against prod — exact commands>
2. <the deploy/restart commands, verbatim from the repo's docs or CI>
3. <post-check: health probe on the deployed instance>
```

### db-migration

```markdown
---
name: db-migration
description: Create and apply a schema migration and regenerate the client. Use when changing the data model.
---

# DB migration

1. Edit `<schema file>`.
2. Dev: `<verified migrate-dev command>` (names the migration) → `<codegen command>`.
3. Prod (if applicable): `<migrate-deploy command with the prod connection>` — see the deploy skill.
4. Run <typecheck> + <test>; never edit `<generated dir>` or committed migrations.
```

## Official code-intelligence (LSP) plugins — offer with compatibility check

LSP plugins from `claude-plugins-official` require their language-server binary on PATH —
verify the current plugin name and required binary via the `research` skill before
offering, never from memory. Known caveat: `typescript-lsp` needs
`typescript-language-server` (wraps tsserver), which does not exist under the native
`typescript@7` (tsgo) preview — flag as incompatible there. Binary missing and not
trivially installable → skip, with a one-line reason in the proposal.

## Other-agent bridges (opt-in only)

Generated only for the agents the user selected in the step-3 batched question (asked
on every run; repo signs only pre-fill the suggested answer) — never by default.
Harness-dependent details (paths, enums, event names) are verified via
the `research` skill before writing: Codex ships near-daily and Gemini's successor
(Antigravity CLI) may move things.

### Shared skills directory (Codex + Gemini)

Codex CLI and Gemini CLI read project skills from `.agents/skills/` (Gemini also from
`.gemini/skills/`; within the same tier the `.agents/skills` alias wins). Claude Code
reads `.claude/skills/` — bridge with a relative symlink, keeping `.claude/skills/`
canonical:

```bash
ln -s .claude/skills .agents/skills   # from the repo root; commit the symlink
```

Windows teams: symlinks need admin rights or Developer Mode — document the command as a
manual step in the README instead of creating it (same caveat as `ln -s AGENTS.md CLAUDE.md`).

### .gemini/settings.json — make Gemini read AGENTS.md

The entire Gemini bridge (Gemini CLI does not read `AGENTS.md` by default). Append
`"GEMINI.md"` to the array only if the project already has one:

```json
{
  "context": {
    "fileName": ["AGENTS.md"]
  }
}
```

### .codex/config.toml — project-scope Codex defaults

Loads only for trusted projects (`codex trust`). Project scope cannot set `notify`,
`profiles` or `model_providers` (global-only keys); never set
`model`/`model_reasoning_effort` here (personal preference, not shared config).
`[profiles.x]` tables are removed syntax (Codex ≥ 0.134) — profiles live in separate
`~/.codex/<name>.config.toml` files, out of project scope.

```toml
sandbox_mode = "workspace-write"
approval_policy = "on-request"

# Mirror the .mcp.json entries the project relies on (Codex does not read .mcp.json).
# Rename the example table to the real server name.
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp@latest"]
```

### .codex/hooks.json — only when mirroring a Claude Code guarantee

Offer only when this same session generates the equivalent Claude Code hook (e.g. a
formatter), so the two configs stay in lockstep instead of diverging. Codex event names
are near-identical to Claude Code's; `matcher` is a regex; `timeout` is in seconds.

```json
{
  "description": "Format on edit (mirrors the .claude/settings.json PostToolUse hook)",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "edit|write",
        "hooks": [
          { "type": "command", "command": "<verified formatter cmd>", "timeout": 60 }
        ]
      }
    ]
  }
}
```

### AGENTS.override.md (rare)

Codex reads `AGENTS.override.md` INSTEAD of the plain `AGENTS.md` at the same directory
level. Offer only for a genuine per-agent conflict (e.g. a command one agent must never
run); otherwise one shared `AGENTS.md` is always simpler.

## Third-party due diligence (skills / plugins / MCP servers)

Two risk tiers, applied before installing anything not already vetted:

- **Official/curated** (`claude-plugins-official`, `anthropics/skills`, `dev-plugins`):
  install after the compatibility check (required binary/toolchain present).
- **Community/unvetted** (open marketplaces, arbitrary repos — ecosystem scans have found
  roughly a third of community skills flawed and hundreds outright malicious): before
  installing, (1) read every SKILL.md, hook and script it ships — they run with the
  user's permissions; (2) check publisher identity and repo history; (3) prefer pinning
  to a commit SHA over a moving tag; (4) after enabling, run
  `claude plugin details <name>` to audit its context cost. User declines the review →
  do not install.

## .gitignore additions

```
CLAUDE.local.md
.claude/settings.local.json
```

When env/secrets files are not already ignored, also:

```
.env*
!.env.example
secrets*.env
```
