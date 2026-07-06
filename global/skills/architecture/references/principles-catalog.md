# Architecture principles catalog — per project type, with applicability signals

Consumed by `/setup-project` (step 3) and usable standalone when restructuring. Stack-agnostic:
every signal is detectable in any language. The catalog never overrides observed reality —
in legacy/active codebases, what the code already does OUTRANKS any principle here.

## Selection protocol

1. **Classify the project** (from step-1 discovery, no extra scanning):
   type — `api-service · ui-web · mobile-app · library-sdk · cli · worker-pipeline ·
   monorepo-mixed` (a repo can be two, e.g. api-service + worker); maturity — greenfield /
   active / legacy; size (file count); team (solo / multiple).
2. **Detect the architecture already present**: folder layout, import/dependency direction,
   where tests live, how config reaches the code. This is the baseline to formalize, not
   replace.
3. **Grade each candidate principle** from the matching sections below against its
   *Apply when / Skip when* signals. Verdict per principle:
   - `adopt` — the code already follows it → state it as a verifiable repo rule so future
     sessions keep it;
   - `propose` — real gap with clear value → offer it in the step-4 proposal, user decides;
   - `discard` — signals say it does not pay here → one-line reason in the proposal.
   Any subset is a valid outcome, including adopting none.
4. **Rewrite before writing**: every adopted/proposed principle becomes one line naming this
   repo's real directories/modules, checkable by reading code ("handlers in `src/routes/`
   never import `src/db/` directly — go through `src/services/`"). If it cannot be made
   repo-specific and verifiable, discard it. Never emit principle names alone (no "apply
   SOLID/DRY/hexagonal").
5. **Destination and budget**: 3–6 bullets max in root CLAUDE.md `## Architecture` (inside
   the ≤ ~60-line budget), or a `paths:`-scoped `.claude/rules/architecture.md` when
   area-specific. Non-obvious decisions and rejected alternatives go to `ARCHITECTURE.md`
   (step-4 approval required — see templates).

## Cross-cutting (evaluate for every type)

- **One-way dependency direction** — name the allowed direction between top-level areas.
  *Apply when:* ≥ 2 sibling areas exist. *Skip when:* single flat module, few files.
- **Config via environment at the edge** — one config module reads env/files; core code
  receives values. *Apply when:* the code runs in ≥ 2 environments. *Skip when:* throwaway
  script.
- **Errors handled at boundaries** — transport/IO edges translate failures; core code
  propagates, never swallows. *Apply when:* always, phrased for this repo's edges.
- **Tests colocated with the unit of change** — state where tests live so features ship with
  them. *Apply when:* a test runner exists (else propose one first).

## api-service

- **Transport/domain split** — handlers parse+validate+respond; domain logic lives outside
  them. *Apply when:* any handler exceeds trivial CRUD glue. *Skip when:* pure proxy/BFF
  with no logic.
- **Feature/slice locality** — one operation's handler, types and tests sit together.
  *Apply when:* operations are the unit of change (most APIs). *Skip when:* an established
  layered layout already works — formalize that instead.
- **Statelessness** — no in-process session/cache the correctness depends on. *Apply when:*
  service is or will be replicated. *Skip when:* explicitly single-instance by design (state
  the fact).
- **Timeouts + idempotency on outbound calls** — every external call has a timeout; retried
  writes are idempotent. *Apply when:* the service calls other services/DBs over the network.

## ui-web / mobile-app

- **Feature-first grouping** — `features/<name>/` holds components+state+tests; no global
  `components/`+`hooks/` dumps beyond a curated shared/ui layer. *Apply when:* > ~3 screens
  or features. *Skip when:* micro-app of 1–2 screens.
- **Single data-access layer** — all remote IO goes through one client/repository layer;
  views never fetch directly. *Apply when:* > 1 place performs remote IO.
- **State/render separation** — business state managed outside render code (per the repo's
  chosen mechanism — name it). *Apply when:* shared or persisted state exists.
- **Navigation as a module** (mobile) — routes declared in one place, screens don't build
  ad-hoc navigation. *Apply when:* > ~5 screens.

## library-sdk

- **Minimal explicit public surface** — one entry point exports the API; everything else is
  internal. *Apply when:* always for libraries. *Skip when:* internal-only helper package
  where the boundary is the repo.
- **No side effects on import/init** — importing the library does nothing until called.
  *Apply when:* always.
- **Compat discipline** — breaking changes only in majors; deprecate before removing.
  *Apply when:* the library has external consumers. *Skip when:* consumers live in the same
  repo (monorepo section applies instead).

## cli

- **Parse/execute split** — argument parsing maps to plain functions; logic is callable
  without a TTY (testable). *Apply when:* more than one command or any nontrivial logic.
- **stdout = result, stderr = diagnostics, exit codes meaningful** — *Apply when:* output may
  be piped/scripted. *Skip when:* purely interactive tool.

## worker-pipeline

- **Idempotent handlers** — reprocessing a message/job is safe; state the dedup mechanism.
  *Apply when:* delivery is at-least-once (queues, cron retries). This is the default; exactly-
  once claims need proof.
- **Explicit retry policy** — backoff + dead-letter/park path defined per job type.
  *Apply when:* jobs can fail transiently.
- **Reliable side-effects** — DB write + event publish are atomic (outbox or equivalent).
  *Apply when:* a write and a publish must not diverge. *Skip when:* side effects are
  best-effort (say so).

## monorepo-mixed

- **Packages depend through public contracts** — imports only via each package's declared
  entry point, never deep paths. *Apply when:* ≥ 2 packages import each other.
- **Inter-package dependency direction** — name the allowed graph (`apps → libs`, shared
  never imports apps). *Apply when:* a shared/libs package exists.
- **Ownership per package** — each package's CLAUDE.md states its rules; root only orients.
  *Apply when:* packages have different stacks or conventions.

## Enforcement tooling (propose the executable rule, not just prose)

When the ecosystem has a maintained tool, an adopted dependency/boundary rule should also be
proposed as config + a CI/test entry (step-4 approval; wire into the existing runner):

| Ecosystem | Tool | Enforces |
|---|---|---|
| JS/TS | `dependency-cruiser` (CI graph rules) · `eslint-plugin-boundaries` (editor feedback) · Nx module boundaries in Nx repos | import direction, cycles, layer boundaries |
| JVM (Java) | ArchUnit (bytecode-level, JUnit) | layers, naming, dependency rules |
| Kotlin / KMP | Konsist (Kotlin-aware; ArchUnit misses Kotlin specifics) | architecture + convention tests |
| Go | `depguard` via golangci-lint (import allow/deny) · `go-arch-lint` (component rules in YAML) | import boundaries, arch components |
| Python | `import-linter` (layers/independence contracts) | layered architecture, forbidden imports |
| .NET | ArchUnitNET (maintained) — original NetArchTest unmaintained since 2023; `NetArchTest.eNhancedEdition` if its fluent API is preferred | dependency + naming rules as tests |
| Dart/Flutter | `import_lint` (analyzer plugin, Dart ≥ 3.10) | restricted import paths |

Verify the current setup syntax with the `research` skill before generating config — never
from memory.
