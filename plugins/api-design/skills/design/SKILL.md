---
name: design
description: API design decisions — REST vs GraphQL vs gRPC choice, resource modeling, versioning, pagination, error shapes, idempotency and OpenAPI documentation. Use when designing new API surfaces or endpoints in any stack.
---

# API design

## Choosing the style
- **REST** (default): CRUD-shaped resources, public APIs, broad client compatibility, HTTP caching matters.
- **GraphQL**: many client shapes over the same graph (mobile + web with different needs), aggregation over several services. Costs: caching, N+1 discipline, query complexity limits.
- **gRPC**: service-to-service internal calls, streaming, tight latency budgets, schema-first contracts. Not for browsers without a proxy.
- Justify any non-default choice in one sentence in the design doc/PR. Details per style: [references/rest.md](references/rest.md), [references/graphql.md](references/graphql.md), [references/grpc.md](references/grpc.md).

## Resource modeling (REST)
- Model nouns, not workflows: `/orders/:id`, sub-resources for real containment (`/orders/:id/items`). Non-CRUD actions become sub-resources (`POST /orders/:id/cancellation`), never verbs in paths.
- IDs are opaque strings to clients (UUIDv7/ULID preferred — sortable, non-enumerable).
- Consistency of shape beats elegance of any single endpoint.

## Versioning and evolution
- Version from day one (`/v1/`). Additive changes (new optional fields) don't bump; removals/semantic changes do.
- Deprecate with headers (`Deprecation`, `Sunset`) and a dated removal plan; never break silently.

## Pagination, filtering, sorting
- Cursor pagination by default (`?cursor&limit`, response `meta.nextCursor`); offset only for small, admin-style tables.
- Filters as explicit query params (`?status=active`); document each one. Sorting `?sort=-createdAt`.

## Errors
- One envelope everywhere: HTTP status + stable machine `code` + human `message` + `requestId`. Clients branch on `code`. 4xx = caller can fix; 5xx = we broke; never 200-with-error-body.

## Idempotency
- All writes that a client may retry (payments, order creation) accept `Idempotency-Key`; store key→result and replay the stored response on retry. PUT/DELETE are idempotent by design; POST needs the key.

## Documentation
- Every HTTP API ships a generated OpenAPI spec; code↔spec drift is a bug.
- When creating or configuring a backend service without one, ask the user once whether to
  configure OpenAPI/Swagger, then set it up fully per the stack plugin (nestjs
  `api-conventions` · dotnet `architecture` · go `tooling`).
