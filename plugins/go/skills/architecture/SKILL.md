---
name: architecture
description: Go project architecture — cmd/internal layout, package design, error handling with wrapping, context propagation and interface placement. Use when creating or restructuring Go packages, services, or CLIs.
---

# Go architecture conventions

## Layout
- Binaries under `cmd/<name>/main.go` (thin: flag/config parsing, wiring, run). All application code under `internal/`; only deliberately reusable libraries go in `pkg/` (rare — default to `internal/`).
- Group by feature/domain (`internal/order/`, `internal/billing/`), not by kind (`internal/models/`, `internal/utils/` are forbidden).
- Package names: short, lowercase, singular, no underscores; the package name is part of the API (`order.Service`, not `order.OrderService`).

## Interfaces
- Define interfaces where they are consumed, not where implemented. Keep them small (1–3 methods); accept interfaces, return concrete structs.
- Don't create an interface until a second implementation or a test seam actually needs it.

## Error handling
- Wrap with context at each boundary: `fmt.Errorf("loading order %d: %w", id, err)`; inspect with `errors.Is`/`errors.As`, never string matching.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) or typed errors per package for branches callers must distinguish.
- Handle every returned error; `_ =` only with a comment stating why it is safe.
- Errors are values: no panics in library code; `panic` only for programmer errors at startup (bad wiring, invalid config).

## Context
- `ctx context.Context` is the first parameter of any function that does I/O, blocks, or crosses a process boundary. Never store contexts in structs.
- Honor cancellation in loops and long operations (`select` on `ctx.Done()`).

## Concurrency
- Prefer `errgroup.Group` (with `SetLimit` for bounded fan-out) over raw goroutines + WaitGroup.
- Every goroutine has a defined owner and exit condition; no fire-and-forget.
- Channels for ownership transfer/signaling; mutexes for shared state — don't force channels where a mutex is simpler.
