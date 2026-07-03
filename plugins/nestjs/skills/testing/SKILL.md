---
name: testing
description: NestJS testing conventions — Jest unit tests, e2e tests via the Fastify inject API, provider mocking and coverage expectations. Use when writing or fixing tests in a NestJS project.
---

# NestJS testing conventions

## Layout and naming
- Unit tests next to the code: `<name>.spec.ts`. E2e tests in `test/` as `<feature>.e2e-spec.ts`.
- One `describe` per class, nested `describe` per method, `it` names state behavior: `it('returns 404 when the user does not exist')`.

## Unit tests
- Build the unit under test with `Test.createTestingModule` and override providers with focused mocks — mock only direct dependencies, never transitive ones.
- Prefer plain object mocks (`{ findById: jest.fn() }`) typed with `jest.Mocked<T>` over auto-mocking libraries.
- Do not mock what you own and can run cheaply (pure helpers, mappers) — test through them.
- Repositories/ORM are mocked in service tests; query logic itself is covered by integration tests against a real database (Testcontainers or docker compose service).

## E2e tests
- Boot the real app with the Fastify adapter and use `app.getHttpAdapter().getInstance().inject()` (no network socket, faster and deterministic) or `supertest` against `app.getHttpServer()` when middleware behavior matters.
- Apply the same global pipes/filters as `main.ts` — extract app setup into a shared `configureApp(app)` used by both.
- Each e2e file seeds and cleans its own data; tests never depend on execution order.

## What to cover
- Every service method: happy path + each error branch.
- Every controller: validation rejection (400), auth guard (401/403), not-found (404).
- Run `npm test` (or `pnpm test`) before declaring done and report the real output.
