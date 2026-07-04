---
name: api-conventions
description: REST API design conventions for NestJS services — URL/versioning scheme, error envelope, pagination and OpenAPI documentation. Use when designing or modifying HTTP endpoints, response shapes, or Swagger docs.
---

# API conventions

## URLs and versioning
- URI versioning via Nest's built-in `app.enableVersioning({ type: VersioningType.URI })` → `/v1/...`.
- Paths: plural kebab-case resources (`/v1/user-profiles/:id`); no verbs in paths — actions that don't map to CRUD get a sub-resource (`POST /v1/orders/:id/cancellation`).
- JSON properties: camelCase.

## Error envelope
All error responses share one shape, produced by a single global exception filter:

```json
{
  "statusCode": 404,
  "error": "Not Found",
  "message": "User 42 not found",
  "code": "USER_NOT_FOUND",
  "requestId": "..."
}
```

- `code` is a stable machine-readable constant per error type; clients switch on `code`, never on `message`.
- Validation errors return `400` with `message` as an array of field errors.

## Pagination
- List endpoints are always paginated. Default: cursor-based (`?cursor=...&limit=...`) for feeds/large sets; offset (`?page=&pageSize=`) only for small admin tables.
- Response envelope: `{ "data": [...], "meta": { "nextCursor": ... } }`.

## OpenAPI
- Bootstrap once in `main.ts` via `SwaggerModule`/`DocumentBuilder` serving `/docs` (disabled or auth-gated in prod); verify the current `@nestjs/swagger` setup via `/research` when adding it.
- Every endpoint gets `@ApiOperation` + `@ApiResponse` for each status it can return; DTOs get `@ApiProperty` (use the swagger CLI plugin to infer where possible).
- Group with `@ApiTags(<feature>)`. Auth-protected endpoints declare `@ApiBearerAuth()`.
- The spec is generated, never hand-edited; treat drift between code and spec as a bug.
