---
name: ui-state
description: React UI and state conventions — Tailwind usage, server-state vs client-state split, forms and validation. Use when building React components, styling with Tailwind, managing state, or implementing forms.
---

# UI and state conventions

## Tailwind
- Tailwind utilities directly in JSX; extract a component (not an `@apply` class) when a pattern repeats.
- Class merging with `cn()` (clsx + tailwind-merge); variant-driven components with `class-variance-authority` when a component has real variants (size, intent).
- Design tokens (colors, spacing, radii) live in the Tailwind config/theme — no arbitrary one-off values (`w-[13px]`) without a comment justifying them.
- Dark mode via the `dark:` variant against CSS variables defined at `:root`/`.dark`.

## State: pick the narrowest tool
1. Local `useState`/`useReducer` — component-local UI state.
2. URL (`searchParams`) — anything shareable/bookmarkable: filters, tabs, pagination.
3. TanStack Query — all server state (cache, revalidation, optimistic updates). Never copy server data into a global store.
4. Context — low-frequency app-wide values (theme, session).
5. Zustand — only for genuinely global, frequently-changing client state that context would re-render too broadly. Adding it is an architecture decision, say why.
- Derive, don't sync: if a value can be computed from props/state, compute it (memoize if hot) instead of mirroring it in another `useState` + effect.

## Forms
- React Hook Form + zod (`zodResolver`); the zod schema is the single source of truth and is shared with the server action validating the same input.
- Accessible by construction: every input has a label, errors are announced (`aria-describedby`), submit buttons show pending state (`useFormStatus` / `formState.isSubmitting`).
- Simple one-field forms may use a plain server action + `useActionState` instead — don't reach for RHF by default.
