---
name: testing
description: .NET testing conventions — xUnit v3 unit tests, WebApplicationFactory integration tests and Testcontainers for real SQL Server. Use when writing or fixing any test in a C#/.NET project, or deciding what kind of test a change needs.
---

# .NET testing (xUnit v3)

## Layers
- **Unit**: pure logic, no I/O, no mocking framework marathons — if a class needs 5 mocks,
  the design is wrong, fix the design. NSubstitute when a test double is genuinely needed.
- **Integration** (the valuable layer for APIs): `WebApplicationFactory<Program>` boots
  the real pipeline (DI, middleware, serialization); override only external dependencies
  via `WithWebHostBuilder`.
- **Database**: Testcontainers `MsSqlBuilder` gives a real SQL Server per test class —
  EF InMemory provider lies about relational behavior, don't use it beyond pure-logic
  scaffolding. Share one container per collection (`IClassFixture`/`ICollectionFixture`)
  and reset state between tests (Respawn).

## Conventions
- Naming: `Method_Scenario_ExpectedOutcome`; Arrange/Act/Assert blocks separated by one
  blank line, no comments labeling them.
- One behavioral assertion focus per test; xUnit built-in asserts are enough — introduce
  an assertion library only if the team already standardized one.
- `[Theory]` + `[InlineData]`/`[MemberData]` for input matrices — the C# analogue of Go
  table-driven tests.
- Async tests return `Task`; no `async void`; pass the test's `CancellationToken`
  (xUnit v3 `TestContext.Current.CancellationToken`) into awaited calls.

## Commands
- Single test while iterating: `dotnet test --filter "FullyQualifiedName~<TestName>"`.
- Full suite + coverage before declaring done:
  `dotnet test --collect:"XPlat Code Coverage"`.
- CI parity: same containers via Testcontainers — no "works locally, mocks in CI" split.
