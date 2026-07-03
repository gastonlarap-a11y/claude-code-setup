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

## Config maintenance
<maintenance block>
```

Per-package `CLAUDE.md`: same shape as the single-package skeleton, minus repo-wide rules.

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
generated/vendored paths found in step 1.

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
