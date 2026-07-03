---
name: architecture
description: Decision framework for architecture and design patterns — choosing between vertical slices, layered, hexagonal, or modular monolith; when a design pattern earns its place; scalability and readability criteria. Use when starting a project, restructuring modules, or justifying a pattern choice.
---

# Architecture decision framework

## First principles
- Architecture exists so the NEXT person (or me in 6 months) can find and change things safely. Optimize for locality of reference and low coupling, not for pattern purity.
- Start with the simplest structure that fits, and make boundaries explicit so it can evolve. A modular monolith that can be split later beats premature microservices.
- Every non-obvious structural decision gets one paragraph in `ARCHITECTURE.md`: what, why, what was rejected.

## Choosing a structure
- **Vertical Slice (VSA)** — default for APIs/services (this is what template-nestjs uses): one folder per operation with handler + DTOs + tests together. Best when operations are the unit of change.
- **Hexagonal / ports & adapters** — when the domain logic is genuinely complex AND must be isolated from multiple infrastructures (e.g., same core used by CLI + API + queue consumers). The cost is indirection; don't pay it for CRUD.
- **Layered (controller/service/repo)** — acceptable for small, uniform CRUD services; degrades as the domain grows because change spreads across layers.
- **Feature-first UI structure** — React/Next/Flutter/Android: group by feature (`features/<name>/` with components, state, tests), not by kind (`components/`, `hooks/` global dumps). Shared UI goes to a curated `ui/`/`shared/` with a barrel.
- **Microservices** — only with a real organizational or scaling driver (independent deploy cadence, isolated failure domains, team boundaries). Never as a starting point for a solo project.

## When a design pattern earns its place
Apply a pattern when its problem is present, and NAME it in the code/PR:
- **Strategy** — behavior varies by a runtime dimension already causing `if/switch` sprawl in 2+ places.
- **Factory** — construction logic is non-trivial or must be swapped in tests; otherwise use plain constructors/DI.
- **Repository** — only when the data source genuinely varies or the query layer needs isolation for testing; direct ORM injection is fine for slices (see template-nestjs rule: no repository over Prisma).
- **Decorator/Middleware** — cross-cutting concerns (auth, logging, metrics) — never bake them into business logic.
- **Observer/Events** — decoupling side-effects (email on signup) from the main flow; introduce an outbox if delivery must be reliable.
- **CQRS** — only when read and write models demonstrably diverge; not by default.
Anti-rule: if you cannot state the problem a pattern solves in one sentence, don't use it.

## Scalability checklist (design time)
1. Statelessness: can this service run with N replicas right now? (No local state, sessions externalized.)
2. What is the growth axis — data volume, request rate, or team size? Design for the real one.
3. Backpressure and timeouts on every external call; idempotency on every retryable write.
4. Observability from day one: structured logs with correlation IDs, health endpoints, basic metrics.
5. Config via environment (12-factor); no environment-specific code paths.

## Readability checklist (for future collaborators)
1. Can someone locate the code for a feature from the folder names alone?
2. Do names describe domain intent (`applyRecurringExpenses`) instead of mechanics (`processData`)?
3. Is each dependency direction one-way and enforced (e.g. `src → libs`, never back)?
4. Are the tests readable as usage examples?
5. Is there exactly one obvious way to do each common task in this repo?
