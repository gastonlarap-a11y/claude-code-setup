---
name: architecture
description: ASP.NET Core project architecture on .NET 10 LTS / C# 14 — minimal APIs vs controllers, dependency injection, options pattern, vertical-slice layout, error handling and OpenAPI documentation. Use when creating or restructuring any C#/.NET service, endpoint, or project, and when answering how a .NET solution should be organized or documented.
---

# .NET architecture (.NET 10 LTS, C# 14)

## Project layout
- Vertical slices over horizontal layers: `Features/<Feature>/` holds endpoint + handler +
  request/response records + validation together. Shared infrastructure (persistence,
  auth) lives in `Common/` or a separate project only when 2+ features need it.
- Solution shape for a service: `src/<Name>.Api` (+ `<Name>.Migrations` if EF worker) and
  `tests/<Name>.Tests` — don't scaffold Domain/Application/Infrastructure projects until
  a real boundary demands them.
- `<Nullable>enable</Nullable>` and `<TreatWarningsAsErrors>` in `Directory.Build.props`
  — one place, all projects.

## Endpoints
- Minimal APIs by default (`MapGroup` per feature, `TypedResults` for compile-checked
  responses). Controllers only when you need their filters/model-binding ecosystem.
- Request/response types are `record`s; never expose EF entities from an endpoint.
- Errors: `ProblemDetails` everywhere (`AddProblemDetails()` + `IExceptionHandler` for
  the unhandled case); domain failures return typed results (`Results<Ok<T>, NotFound>`),
  not exceptions.

## Dependency injection
- Constructor injection only; lifetimes: singleton for stateless services, scoped for
  anything touching `DbContext`, transient rarely. Never resolve scoped from singleton.
- Configuration via options pattern: `IOptions<XOptions>` bound + validated at startup
  (`ValidateDataAnnotations().ValidateOnStart()`) — fail fast, not on first use.

## Async
- Async all the way down — no `.Result`/`.Wait()` (deadlocks + thread starvation);
  `CancellationToken` accepted and forwarded in every I/O path (endpoints get it free).

## API documentation (OpenAPI)
- Built-in `Microsoft.AspNetCore.OpenApi`: `AddOpenApi()` + `MapOpenApi()` generate the
  document — Swagger UI no longer ships in templates; interactive UI via `Scalar.AspNetCore`,
  mapped in Development only.
- Enrich minimal-API groups with `WithSummary`/`WithTags`/`Produces<T>` so the spec stays
  useful; the spec is generated, never hand-edited — code↔spec drift is a bug.
- Verify exact packages and current idiom via `/research` before wiring it.

## Local orchestration & learning
[references/aspire.md](references/aspire.md) — Aspire AppHost for local SQL Server/Redis
etc. · [references/learning-path.md](references/learning-path.md) — official learning
route for this stack. Verify library versions via `/research`.
