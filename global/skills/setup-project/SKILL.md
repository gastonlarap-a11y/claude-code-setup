---
name: setup-project
description: Create, audit or improve a project's Claude Code configuration (CLAUDE.md, README, .claude/rules, skills, settings, plugins) adapted to the project's real stack, size and conventions. Use when a project has no CLAUDE.md or .claude/ config, when the user asks to set up, review or improve the AI/agent configuration, or when drift is detected (a documented command fails, a stated convention contradicts the code). Works on new, legacy and already-configured projects; never discards existing instructions.
argument-hint: "[optional focus: audit | a subdirectory | a concern like 'testing']"
---

# Project configuration protocol

Goal: after this runs, every session in this project starts with maximum real context at
minimum token cost, and the config keeps itself current (step 6). The project's own code is
the source of truth: derive conventions from what exists; never impose foreign style on an
established codebase.

Scope/focus: $ARGUMENTS (empty = full pass on the current project).

Hard rules:
- **Preserve intent.** Never silently delete or rewrite existing instructions (CLAUDE.md,
  AGENTS.md, .cursorrules, …). Reorganize, dedupe and tighten — and list every dropped or
  changed line in the step-4 proposal.
- **Verify, don't trust.** Every command you document must have been run by you here (or
  copied verbatim from CI). Every path you mention must exist.
- **Ask when signals conflict** (two package managers, mixed test runners, docs that
  contradict code): ask the user; never pick silently. Also ask the step-3 proactive
  questions — batched, once.
- **Nothing is written before the step-4 proposal is approved.**
- Config files in English. Conversation and report in the user's language.

## 1. Discover (read-only)

- **Stack**: manifests (`package.json`, `go.mod`, `pubspec.yaml`, `build.gradle(.kts)`,
  `settings.gradle*`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `composer.json`,
  `*.csproj`, `Gemfile`, `pom.xml`, `mix.exs`, …), frameworks, entry points; package manager
  from lockfiles; language/tool versions from configs.
- **Shape**: monorepo markers (`pnpm-workspace.yaml`, `workspaces`, `turbo.json`, `nx.json`,
  `go.work`, `melos.yaml`, Gradle `include`s) and their packages; approximate size
  (`git ls-files | wc -l`); generated/vendored directories.
- **Commands** (run each one; broken ones are flagged here and fixed via the step-4
  proposal, or discarded): test, lint,
  typecheck/analyze, format, build, dev/run, migrations, codegen. Sources: manifest scripts,
  Makefile/Taskfile/justfile, CI workflows.
- **Conventions**: sample 2–3 recently-active feature areas (`git log --stat`) and record
  observed patterns: layout, naming, error handling, test placement/style, DI, state
  management. In legacy projects these observations OUTRANK generic best practices.
- **Architecture**: classify the project type(s) (api-service, ui-web, mobile-app,
  library-sdk, cli, worker-pipeline, monorepo-mixed) and record the structure already
  present: top-level areas, import/dependency direction, where domain logic vs transport/IO
  lives. Feeds the step-3 principle selection.
- **Existing AI config** (full inventory): `CLAUDE.md`, `CLAUDE.local.md`, `.claude/**`
  (settings, rules, skills, hooks, agents, commands), `AGENTS.md`, `.cursorrules`,
  `.cursor/rules/`, `.windsurfrules`, `.github/copilot-instructions.md`, `.mcp.json`,
  nested `CLAUDE.md` files in subdirectories.
- **Ecosystem**: `claude plugin marketplace list` (is `gaston-plugins` or another relevant
  marketplace registered?), `claude plugin list`, `claude mcp list`.
- **Docs**: README/ARCHITECTURE/CONTRIBUTING — read them; config points to them, never
  duplicates them into CLAUDE.md. Diff the README against the skeleton in
  `references/templates.md`: missing sections and commands proven wrong become step-3 work.

## 2. Audit the existing config (skip when there is none)

Grade every existing instruction against this checklist. Each finding becomes
keep / tighten / move / add / retire — retire is always shown to the user, never silent.

- **Accuracy**: documented commands actually pass; named paths/modules exist; versions match
  the lockfiles.
- **Budget**: the root instruction file — CLAUDE.md plus any @-imported AGENTS.md — stays
  ≤ ~60 lines for a typical repo (hard cap 150; official guidance
  is < 200). Only always-true, always-needed facts: what the project is, layout map,
  verified commands, hard do/don'ts. Litmus test per line: *would removing it cause Claude
  to make mistakes? If not, cut it.* Never include: what reading the code already shows,
  standard conventions of the language, or information that changes frequently.
- **Placement** — the core efficiency move; wrong placement is what wastes tokens:
  - language/area-specific guidance → `.claude/rules/<topic>.md` with `paths:` globs
    (loads only when touching matching files);
  - multi-step procedures (release, migration, scaffolding, deploy) →
    `.claude/skills/<name>/SKILL.md` (loads on demand; `disable-model-invocation: true`
    for side-effectful ones);
  - guarantees ("never edit X", "always format") → `permissions.deny` or hooks, not prose;
  - reference material → skill `references/*.md`, loaded only when the topic comes up.
- **Duplication/conflicts**: nothing the code, README or manifests already state; no rule
  repeated across files; no contradictions (Claude resolves them arbitrarily — fix them).
- **Other-tool configs**: `AGENTS.md` present → root CLAUDE.md becomes `@AGENTS.md` import
  plus Claude-specific deltas below it (one shared source for all agents). `.cursorrules`
  & co. → merge their still-true content into the shared files; leave the originals alone.
- **Coverage gaps**: missing test/lint/build commands, no architecture map, routine commands
  not pre-approved in permissions, secrets not deny-listed, generated/vendored dirs not
  read-blocked.

## 3. Design the target config

Compose only from what the project actually needs — a missing section beats a speculative
one. Skeletons for every block: `references/templates.md` (read it before writing files).

| Block | Contents | Budget |
|---|---|---|
| `AGENTS.md` (root, canonical) | identity, layout map, verified commands, hard rules, engineering standards | ≤ ~60 lines |
| `CLAUDE.md` (root, thin) | `@AGENTS.md` import, Claude-only deltas, maintenance block | ≤ ~10 lines |
| `README.md` | human usage docs: always created for new projects, non-destructively updated for existing ones | not context-loaded — thorough beats terse |
| `.claude/rules/<topic>.md` | per-language/area conventions derived from observed code, `paths:`-scoped | ≤ ~40 lines each |
| `.claude/settings.json` | `enabledPlugins`, `permissions.allow` for the verified routine commands, `permissions.deny` for secrets + generated/vendored reads | — |
| `.claude/skills/<name>/` | repeated procedures found in step 1, as done HERE | on demand |
| Hooks | only for guarantees with a deterministic tool behind them (e.g. formatter configured) | zero context |
| `CLAUDE.local.md`, `.claude/settings.local.json` | personal-only bits found in the audit; must be gitignored | — |

Canonical file: with no existing instruction file, generate `AGENTS.md` (the cross-agent
standard — Codex, Cursor and Gemini CLI read it too) plus the thin `CLAUDE.md` that imports
it. A project that already has CLAUDE.md-only keeps CLAUDE.md canonical (full content, as
before) — offer the AGENTS.md split as optional in step 4, never forced. `AGENTS.md` already
present → the step-2 rule applies (import + deltas).

The canonical instruction file (AGENTS.md for fresh configs, CLAUDE.md otherwise) always
includes the engineering-standards block from `references/templates.md`,
minus lines this repo's own config files already cover (never counting anyone's `~/.claude`).

### Architecture principles (selective, auditable)

Run the selection protocol in the `architecture` skill's `references/principles-catalog.md`
against the step-1 classification: grade each candidate principle `adopt` (code already
follows it → verifiable repo rule) / `propose` (high-value gap, user decides) / `discard`
(one-line reason). Any subset is valid, including none. Every kept principle is rewritten
naming this repo's real directories/modules — never a bare principle name. Destination:
`## Architecture` block in root CLAUDE.md (3–6 bullets, inside the budget) or a
`paths:`-scoped `.claude/rules/architecture.md`; where the catalog lists an enforcement tool
for the stack, offer the executable rule too. `ARCHITECTURE.md` (skeleton in
`references/templates.md`) is offered ONLY when non-obvious structural decisions need their
why recorded — never created without step-4 approval.

Creating or configuring a project ALWAYS produces or updates `README.md` (skeleton in
`references/templates.md`; drop speculative sections). Existing README: fill gaps and fix
commands proven wrong in step 1 — never delete or rewrite the user's prose; every change
appears in the step-4 proposal. Language: match the existing docs; brand-new projects
default to English unless the user chooses otherwise ("Ask before proposing"). README
`Commands` and CLAUDE.md `## Commands` mirror the runner entries — one source of truth.

### Command runner (canonical per stack)

| Stack | Runner | Standard entries |
|---|---|---|
| Node family (NestJS/Next.js/RN/TS) | `package.json` scripts | `dev` `build` `test` `test:e2e` `lint` `typecheck` |
| Go | `Makefile` | `run` `build` `test` `lint` `generate` |
| .NET | `dotnet` CLI verbs (native — don't wrap); compound workflows (migrations, infra-up, seed) → `Makefile` or `scripts/*.ps1` (ask) | — |
| Android | Gradle tasks (already native) | — |
| Flutter | `Makefile` (single app) / melos scripts (when `melos.yaml` exists) | `run` `test` `analyze` `build` `gen` |

When verified commands are scattered (CI-only, docs-only, raw multi-flag invocations) or
missing standard names, propose consolidating them into the runner (step-4 approval):
reuse existing names, add missing ones, never rename ones that work.

Plugin mapping when `gaston-plugins` is registered: NestJS → `nestjs` + `api-design` ·
Go service → `go` · Android → `android-kotlin` · Next.js → `react-nextjs` · Flutter →
`flutter` · React Native → `react-native` + `expo@claude-plugins-official` · C#/.NET →
`dotnet` + `api-design` · add `bots` /
`realtime` / `background-jobs` per domain · any project with a user-facing UI (web or
mobile, any framework) → `ux`. Also suggest the official code-intelligence (LSP)
plugin for the project's language if not already enabled.

Stack without a matching plugin, or no marketplace available: encode the equivalent
essentials as local `.claude/rules/` + `.claude/skills/` instead — derived from this
project's code first, completed via the `research` skill (or official docs) only for gaps.
Project skills in `.claude/skills/` load on their own, no marketplace needed (CLI ≥ 2.1.157).
The result must be self-sufficient: the project's config cannot depend on files that exist
only on one person's machine.

Monorepo: root CLAUDE.md only orients (package list + where commands run); each actively
developed package gets its own short `CLAUDE.md` and, if it has its own procedures,
`.claude/skills/`; suggest `claudeMdExcludes` in `.claude/settings.local.json` for areas the
user never touches.

New/empty project: interview the user first — one question at a time, START.md style —
following `references/new-project-interview.md`; its answers stand in for the missing code
evidence and pre-fill the batched questions below (never re-ask what it settled). Existing
projects skip it: code evidence outranks questions. Conventions come from the chosen stack's
plugin or the user's template repo, and the config states the intended architecture so the
very first sessions build it consistently.

### Ask before proposing (batched, one message)

Only questions detection cannot answer — skip any the repo already answers or the
new-project interview already settled:
- Backend HTTP service without OpenAPI → offer OpenAPI/Swagger. If accepted, configure it
  fully per the stack plugin (nestjs `api-conventions` · dotnet `architecture` · go
  `tooling`); record the docs URL in the README and spec-generation in the runner.
- **No CI workflow detected** (new or legacy project) → ALWAYS ask whether to add one
  (built per the `ci-cd` skill). Never create CI without an explicit yes; if CI already
  exists, do not offer.
- Deployment target not detectable → README `Deployment` section.
- Brand-new project → README language.
- .NET only → unix-first (`Makefile`) or Windows-first (`scripts/*.ps1`) team.

## 4. Propose, then apply

Present one compact plan: per file — create / keep / tighten / move / retire, each with a
one-line reason, plus before/after line counts of always-loaded content (that difference is
the per-session token cost). Include the architecture-principle selection as its own list:
adopted / proposed / discarded, one-line reason each — the user edits this selection before
anything is written. Get approval; adjust if redirected. Then write exactly what was
approved.

## 5. Verify

- Re-run every documented command; every mentioned path exists.
- README commands match the runner entries and each one ran in step 1; every README path
  and link exists.
- The engineering-standards block is present in the generated canonical file (AGENTS.md or
  CLAUDE.md).
- Each documented architecture principle spot-checks true against the code today; if an
  enforcement rule was approved, its command runs and passes.
- `wc -l` per file within budget; report total always-loaded lines (CLAUDE.md + imported
  AGENTS.md + unscoped rules) before vs after.
- `.gitignore` covers `CLAUDE.local.md`, `.claude/settings.local.json` and secret files.
- `/doctor` reports no configuration issues for the project.
- Tell the user to open a fresh session and check `/context` (real cost) and that routine
  commands no longer prompt for permission; after a few days, `/usage` shows which skills,
  subagents, plugins and MCP servers actually consume tokens — retire what goes unused.
- Suggest the commit (Conventional Commits style, e.g. `chore: add claude code project
  config`); do not commit unless asked.

## 6. Leave it self-improving

Append this maintenance block to the project CLAUDE.md (verbatim — it is the improvement
loop that keeps the config honest between runs):

```markdown
## Config maintenance
- After ANY task that changed structure, commands or conventions: check that this file — and
  AGENTS.md if present — still matches reality; propose the exact edit in the same session.
- Same-session fix also when a documented command fails, a stated convention contradicts the
  code, or the user corrects the same thing twice.
- New repeated procedure → propose a `.claude/skills/` entry; new language/area convention →
  a `paths:`-scoped rule in `.claude/rules/` — never more always-loaded lines.
- After structural changes (new package, framework migration, tooling swap), re-run
  `/setup-project audit`.
```

Auto memory (machine-local) accumulates personal learnings on its own; during re-audits,
promote anything team-relevant from it into the shared CLAUDE.md/rules.

Optional, offer but do NOT install by default: a `Stop` hook that reviews the session
transcript when a turn ends and proposes CLAUDE.md/rules updates (official pattern from the
large-codebases guide). Warn about its cost — it runs on EVERY turn end; the prose
maintenance block above is the recommended default.

Re-running this skill on an already-configured project = re-audit: diff steps 1–2 against
reality and propose only the delta — including architectural drift: documented principles
the code no longer follows are re-graded (re-adopt, amend, or retire), never left stale.

## 7. Report

In the user's language: files created/changed with line counts (naming which file is
canonical — AGENTS.md or CLAUDE.md), README created/updated
(which sections), what was preserved from the pre-existing config, plugins enabled, each
verified command with its real result, and the always-loaded context total vs before.
