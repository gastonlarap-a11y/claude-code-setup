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
