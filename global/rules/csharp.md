---
paths:
  - "**/*.cs"
---

# C# rules
- Nullable reference types always on; no `!` (null-forgiving) without a justifying comment.
- File-scoped namespaces; one public type per file; `record` for immutable data/DTOs.
- Async methods end in `Async`, return `Task`/`ValueTask`, accept and forward a
  `CancellationToken`; never `async void` (event handlers excepted); never `.Result`/`.Wait()`.
- Pattern matching over type checks/casts; `switch` expressions must be exhaustive.
- Exceptions cross boundaries as `ProblemDetails`/typed results — never swallowed;
  `catch (Exception)` only at top-level handlers with logging.
- LINQ over manual loops when it stays readable; no multiple enumeration of `IEnumerable`.
