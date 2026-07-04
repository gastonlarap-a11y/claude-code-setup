---
name: testing
description: Go testing conventions — table-driven tests, subtests, race detector, golden files and integration test separation. Use when writing or fixing Go tests.
---

# Go testing conventions

## Style
- Table-driven tests with named cases:

```go
tests := []struct {
    name    string
    in      Order
    want    Total
    wantErr error
}{ ... }
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) { ... })
}
```

- Case names are lowercase behavior descriptions ("rejects negative quantity").
- Use `t.Helper()` in assertion helpers; `t.Parallel()` where cases share no state.
- Compare with `go-cmp` (`cmp.Diff`) for structs; report as `t.Errorf("mismatch (-want +got):\n%s", diff)`. Standard library first — add testify only if the repo already uses it.

## Errors in tests
- Assert with `errors.Is`/`errors.As` against exported sentinels/types, never against `err.Error()` strings.

## Golden files
- For large/serialized output, store expected output in `testdata/<case>.golden` and support `-update` flag to regenerate; always diff, never truncate.

## Integration tests
- Separate with build tags (`//go:build integration`) or `testing.Short()` guards; they run against real dependencies (Testcontainers or compose).
- Unit tests must run with no network, no disk state, in milliseconds.

## Commands
- Default run: `go test ./... -race -shuffle=on`. Coverage check: `go test ./... -cover`.
- The race detector is not optional — a PR that only passes without `-race` is broken.
- Run `go vet ./...` alongside tests; report real output.
- When the repo has a `Makefile`, its targets (`make test`, `make lint`) are the source of
  truth — use and extend them instead of raw invocations.
