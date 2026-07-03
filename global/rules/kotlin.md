---
paths:
  - "**/*.{kt,kts}"
---

# Kotlin rules
- Structured concurrency only: no `GlobalScope`; launch in `viewModelScope`/`lifecycleScope` or an injected scope.
- Prefer `val`, data classes and sealed interfaces/classes for state modeling; exhaustive `when` over sealed types.
- Never use `!!`; handle nullability with `?.`, `?:`, `requireNotNull` (with message), or better modeling.
- Inject `CoroutineDispatcher`s (no hardcoded `Dispatchers.IO` in logic) so tests can substitute them.
- Catch specific exceptions; never swallow `CancellationException`.
