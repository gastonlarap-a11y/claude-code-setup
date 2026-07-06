# Skeletons for generated project config

Fill only with verified facts (step 1). Delete any section that would be speculative.
Everything in English. `<angle brackets>` mark what to replace.

## Root CLAUDE.md — single-package repo

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

## Config maintenance
<paste the maintenance block from SKILL.md step 6>
```

If `AGENTS.md` exists, the file starts with `@AGENTS.md` and contains only Claude-specific
deltas below it — no duplicated content.

## Root CLAUDE.md — monorepo (orientation only)

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

## Config maintenance
<maintenance block>
```

Per-package `CLAUDE.md`: same shape as the single-package skeleton, minus repo-wide rules.

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
    "<stack>@gaston-plugins": true
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
          { "type": "command", "if": "Edit(*.<ext>)", "command": "<verified formatter cmd>" }
        ]
      }
    ]
  }
}
```

The `if` filter (permission-rule syntax) keeps the hook from spawning on every edit —
scope it to the files the tool actually handles.

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

## .gitignore additions

```
CLAUDE.local.md
.claude/settings.local.json
```
