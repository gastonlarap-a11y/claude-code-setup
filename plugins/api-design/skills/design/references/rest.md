# REST reference

## Status code map
| Case | Code |
|---|---|
| Created (returns body + `Location`) | 201 |
| Accepted for async processing (returns status URL) | 202 |
| Successful delete / no body | 204 |
| Validation failed | 400 |
| Missing/invalid credentials | 401 |
| Authenticated but not allowed | 403 |
| Resource not found (also: exists but caller may not know) | 404 |
| Conflict with current state (duplicate, stale version) | 409 |
| Precondition failed (`If-Match` ETag mismatch) | 412 |
| Body too large / unsupported media | 413 / 415 |
| Domain-valid but unprocessable | 422 |
| Rate limited (include `Retry-After`) | 429 |

## Concurrency control
- Return `ETag` on reads; require `If-Match` on updates of contended resources → 412 on mismatch.
- Alternative: explicit `version` field checked in the update (optimistic locking) → 409.

## Async operations
- Long-running work: `202 Accepted` + `Location: /v1/operations/:id`; the operation resource exposes `status`, `result`, `error`. Client polls or receives a webhook.

## Bulk endpoints
- Accept an array, respond 207-style with per-item results `{ index, status, error? }`; cap batch size and document it.

## Caching
- `Cache-Control` on safe GETs; `ETag` + conditional requests for cheap revalidation. Vary carefully (`Vary: Authorization` when responses are per-user).

## HATEOAS
- Skip full HATEOAS; include only pragmatic links (`meta.nextCursor`, operation `Location`). Document the API in OpenAPI instead.
