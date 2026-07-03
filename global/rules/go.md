---
paths:
  - "**/*.go"
---

# Go rules
- Wrap errors with context: `fmt.Errorf("doing x: %w", err)`; check with `errors.Is`/`errors.As`, never string matching.
- `ctx context.Context` is the first parameter of anything doing I/O; never stored in structs.
- Accept interfaces, return structs; define interfaces at the consumer, keep them small.
- Tests are table-driven with named subtests; run with `-race`.
- No `panic` in library code; handle or return every error (`_ =` requires a justifying comment).
