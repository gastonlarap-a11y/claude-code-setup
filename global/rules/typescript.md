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

## Hono
- Consume the API with the `hc` RPC client (typed end-to-end); don't hand-write fetch wrappers.
- Keep handlers pure (no module-level mutable state). Inject Prisma / MSSQL and other dependencies through the request `Context` (middleware-provided bindings / `c.get`).

## Bun
- When behavior differs from Node.js, flag it in a comment. Prefer Bun-native APIs for I/O (`Bun.file`, `Bun.write`, `Bun.serve`, `bun:sqlite`) over the Node polyfills.

## Jotai
- Model UI state as small, isolated atoms; compose them instead of one large store atom.
- No `useEffect` to sync atoms; derive state from read-only (derived) atoms.
- Never copy server-state cache (React Query / SWR / RSC data) into atomic stores — atoms hold UI state only.
