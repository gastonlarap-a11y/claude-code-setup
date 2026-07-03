---
name: research
description: Research the current, official way to do something with a library, framework, API or platform — exact method signatures, latest stable versions, integration steps, breaking changes. Use AUTOMATICALLY whenever the task involves a third-party API surface not fully covered by an already-loaded skill, or the user asks "how do I X" with a framework. Never answer such questions from training data.
context: fork
agent: docs-researcher
---

# Research protocol

Research question: $ARGUMENTS (if empty, derive it from the current task).

Rules: search **in English**, prefer the **latest stable** release and **official** sources. Fetch only the sections that answer the question — never whole documentation sites.

## Procedure
1. **Scope the question** into one concrete query: library + version context + specific capability (e.g. "flutter showModalBottomSheet scroll control", "CameraX ImageCapture Compose").
2. **context7 first**: `resolve-library-id` → `query-docs` scoped to the exact topic. This usually suffices.
3. **Official docs fallback** (WebFetch/WebSearch) when context7 lacks coverage: the project's own docs, changelog, release notes, or repository. Ignore blogspam and outdated tutorials; check the doc's version selector matches the latest stable.
4. **Version check**: confirm the current stable version (release page / registry) — never assume from memory.

## Report back (keep under ~400 words)
- **Version**: current stable of the involved package(s).
- **Answer**: minimal working pattern (code snippet in English), including required setup (permissions, config, init) that the docs mark as mandatory.
- **Gotchas**: breaking changes vs older majors, platform caveats.
- **Source**: the exact doc URLs used.
- **Drift flag**: if the finding contradicts a recipe/reference in an enabled plugin (e.g. `flutter:recipes`), say exactly which entry is stale so the main session can suggest running `/refresh-knowledge`.
