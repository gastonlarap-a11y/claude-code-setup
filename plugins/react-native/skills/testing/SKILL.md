---
name: testing
description: React Native testing conventions — Jest + React Native Testing Library for units/components and Maestro for e2e flows. Use when writing or fixing tests in a React Native project.
---

# React Native testing conventions

## Tools
- Jest with `jest-expo` preset; React Native Testing Library (RNTL) + `user-event` for components; MSW for network mocking; Maestro for e2e device flows.

## Component tests (RNTL)
- Query by accessible role/label/text first (`getByRole`, `getByLabelText`, `getByText`); `testID` as last resort.
- Interactions via RNTL's `userEvent` (press, type); async assertions with `findBy*`/`waitFor` — no arbitrary timers. Use fake timers for debounce/animation-dependent logic.
- Mock at the boundaries only: MSW for HTTP; module mocks for native modules that can't run in Jest (keep them in `__mocks__/`, typed). Don't mock your own components.
- Screens render inside a test harness providing QueryClient, theme and (when navigation matters) a router/navigator wrapper — one shared `renderWithProviders` helper.

## Unit tests
- Pure logic (validators, mappers, stores) as plain Jest tests; Zustand stores tested by calling actions and asserting state, resetting between tests.

## E2e (Maestro)
- Flows in `.maestro/*.yaml`; cover launch, auth, and the primary happy path per release — not every screen.
- Select by accessibility id/text consistently with RNTL usage; seed state via test APIs or deep links, not UI walking, wherever possible.
- Run against a `preview` (release-mode) build on emulator/simulator; document the exact `maestro test` invocation in the repo.

## Commands
- `npm test` (or `pnpm test`) + `npm run lint` + `npx tsc --noEmit` before declaring done; report real results. State explicitly when e2e was not run (needs emulator/build).
- All repo commands live in `package.json` scripts with standard names (`dev` `build` `test` `test:e2e` `lint` `typecheck`) — add new ones there, never as prose in docs.
