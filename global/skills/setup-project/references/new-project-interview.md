# New/empty project interview

Used by step 3 ONLY when the project is new/empty — existing projects skip it: code
evidence outranks questions. One question at a time, in the user's language, each with a
sensible default; detected facts are stated, not asked. "You decide" → apply the stack
defaults and list every defaulted choice explicitly in the step-4 proposal. Answers
pre-fill the step-3 batched questions — never re-ask what was settled here.

## Questions (in order)

1. **Purpose** — what is being built and for whom, in one sentence. Becomes the identity
   line of the generated AGENTS.md and drives every later default.
2. **Platform + stack** — offer the stacks with plugin coverage (step-3 plugin table) and
   the user's template repos when relevant. The answer maps to `enabledPlugins`,
   `.claude/rules/`, and the canonical command runner for the stack.
3. **Architecture shape** — classify the project type from answers 1-2, run the selection
   protocol in the `architecture` skill's `references/principles-catalog.md`, and present
   the 2-3 fitting shapes with one-line trade-offs. Chosen principles enter step 3 as
   `adopt` (they describe intent the first sessions must build, not yet code).
4. **Deploy target / CI** — where it will run, and whether to scaffold CI now (built per
   the `ci-cd` skill). Feeds the README `Deployment` section and REPLACES the step-3
   batched CI question.
5. **Testing expectations** — levels and frameworks (default: the stack plugin's testing
   skill), and what "done" must run.

## Then

Proceed through steps 3-4 with the answers as evidence: propose AGENTS.md (canonical) +
the thin CLAUDE.md + only the blocks the answers justify — a missing section still beats
a speculative one. The config states the intended architecture so the very first sessions
build it consistently.
