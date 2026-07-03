---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript rules
- No `any`: use `unknown` plus narrowing, or a proper type. `as` casts need a comment justifying them.
- Type-only imports use `import type { ... }`.
- No floating promises: `await`, return, or explicitly `void` with a reason.
- Named exports only; `export default` is reserved for framework files that require it (e.g. Next.js pages/layouts).
- Model states as discriminated unions instead of boolean flag combinations.
