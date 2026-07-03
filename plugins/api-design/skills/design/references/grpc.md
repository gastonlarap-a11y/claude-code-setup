# gRPC reference

## Contracts
- Proto files are the source of truth, versioned in a dedicated `proto/` (or a shared contracts repo when several services consume them); generated code is never hand-edited.
- Package versioning in the proto package name (`billing.v1`); breaking changes → new package `v2`, run both during migration.
- Field numbers are forever: never reuse or renumber; `reserved` removed fields/numbers.
- Evolve additively: new optional fields are safe; changing types/semantics is a new field + deprecation of the old one.

## Service design
- Unary for request/response; server streaming for feeds/large result sets; client/bidi streaming only with a real need (uploads, sync protocols).
- Errors: canonical status codes (`NOT_FOUND`, `INVALID_ARGUMENT`, `FAILED_PRECONDITION`, `ALREADY_EXISTS`, `UNAVAILABLE`) + `google.rpc.Status` details for machine-readable extras. Map domain errors once, at the handler boundary.
- Deadlines are mandatory: every client call sets a deadline; servers propagate incoming deadlines to downstream calls (context propagation).

## Operational
- Health checking via the standard `grpc.health.v1` service; reflection enabled outside production.
- Retries only on idempotent methods, configured in the client (retry policy in service config), with jittered backoff.
- Browsers/external clients: gRPC-Web or a REST gateway (grpc-gateway / ConnectRPC) — don't expose raw gRPC publicly.
