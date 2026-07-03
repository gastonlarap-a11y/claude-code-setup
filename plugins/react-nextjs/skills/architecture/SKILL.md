---
name: architecture
description: Next.js App Router architecture — server vs client components, data fetching and caching, route handlers, server actions and project structure. Use when creating or restructuring Next.js routes, components, or data-loading code.
---

# Next.js architecture conventions (App Router)

## Structure
- App Router only (`app/`); no new `pages/` code. Route groups `(group)/` for layout scoping, private folders `_components/` for co-located non-route files.
- Shared code outside `app/`: `components/` (reusable UI), `lib/` (pure logic, API clients), `hooks/`. Feature-specific components stay co-located next to their route.

## Server vs client components
- Server components are the default. Add `"use client"` only at true interactivity boundaries (event handlers, browser APIs, stateful hooks) and push it as deep (leaf-ward) as possible.
- Never import a server-only module into a client component; mark boundaries with the `server-only` package.
- Pass data down as serializable props; pass server actions instead of callbacks across the boundary.

## Data fetching and caching
- Fetch in server components, close to where data is used; React deduplicates identical requests within a render. No fetching in `useEffect` when a server component can do it.
- Be explicit about caching: static data → default caching + `revalidate`; per-request data → `cache: 'no-store'` (or `dynamic = 'force-dynamic'`). Tag-based invalidation (`revalidateTag`) after mutations.
- Client-side server state (polling, infinite scroll, optimistic UI) uses TanStack Query — never hand-rolled `useEffect` fetch state machines.

## Mutations
- Server actions (`"use server"`) for form mutations: validate input with zod at the top of the action, return typed `{ ok, error }` results, call `revalidateTag`/`revalidatePath` on success.
- Route handlers (`app/api/.../route.ts`) only for genuine API needs: webhooks, non-HTML clients, streaming.

## Errors and loading
- Each route segment that can fail gets `error.tsx` (client) and meaningful `loading.tsx` / `<Suspense>` boundaries; `notFound()` for missing entities.
- Errors at the data boundary are handled and typed — no silent `catch {}`.
