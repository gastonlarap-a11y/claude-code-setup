---
paths:
  - "**/*.dart"
---

# Dart rules
- Use `const` constructors/values wherever possible (analyzer will point them out — fix, don't ignore).
- Avoid `dynamic`; type everything, use `Object?` + pattern matching when the type is truly open.
- Keep trailing commas on multi-line argument lists so `dart format` produces stable, readable layouts.
- No unawaited futures: `await` them or mark deliberately with `unawaited(...)` from `dart:async`.
- Widgets: prefer composition of small private widget classes over builder methods returning trees.
