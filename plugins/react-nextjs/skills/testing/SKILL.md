---
name: testing
description: React/Next.js testing conventions — Vitest + Testing Library for units/components, Playwright for e2e, MSW for network mocking. Use when writing or fixing tests in a React or Next.js project.
---

# React/Next.js testing conventions

## Tools
- Vitest as the runner (jsdom environment for components); React Testing Library + `user-event` for component tests; MSW for HTTP mocking; Playwright for e2e.
- If e2e work becomes significant, enable the official `playwright@claude-plugins-official` plugin for browser-driven runs.

## Component tests (RTL)
- Test behavior through the accessible surface: query by role/label/text (`getByRole('button', { name: /save/i })`); `data-testid` is the last resort.
- Interactions via `userEvent` (never `fireEvent` unless required); async UI with `findBy*` / `waitFor` — no arbitrary sleeps.
- Mock at the network edge with MSW handlers, not by mocking fetch/axios or child components. Mock a child component only when it's genuinely heavy (maps, charts).
- Pure logic (formatters, reducers, zod schemas) gets plain Vitest unit tests without DOM.

## Server code
- Server actions and route handlers: test as functions — call them with constructed input, assert returned value/thrown redirect, mock only the data layer beneath.
- Async server components are covered by e2e, not unit-rendered.

## E2e (Playwright)
- Cover the critical flows (auth, main CRUD, checkout-like paths) — not every page. Run against `next build && next start`, not the dev server.
- Selectors: role/label first; isolate state per test (fresh user/data via API seeding); no test order dependencies.

## Commands
- `pnpm test` (or `npm test`) for unit/component; `pnpm exec playwright test` for e2e; always also run `pnpm lint` and `pnpm typecheck` before declaring done and report real results.
