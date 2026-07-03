---
name: architecture
description: React Native + Expo architecture — Expo Router structure, native module boundaries, EAS build profiles and performance basics. Use when creating or restructuring React Native screens, native integrations, or build configuration.
---

# React Native architecture conventions (Expo)

## Baseline
- New apps are Expo apps (managed workflow + prebuild when native code is needed) — bare React Native only when a hard requirement forces it, stated explicitly.
- File-based navigation with Expo Router: routes in `app/`, shared code in `components/`, `lib/`, `hooks/`; feature code co-located under `features/<name>/` with screens re-exported from `app/` route files kept thin.

## Navigation (Expo Router)
- Typed routes enabled (`experiments.typedRoutes`); layouts (`_layout.tsx`) own navigators (Stack/Tabs), auth gating via a root layout redirect driven by session state.
- Deep links come free from file routes — keep route params serializable and validated (zod) at the screen boundary.

## State and data
- Same rules as web React: server state in TanStack Query; local UI state in components; Zustand only for genuinely global client state; persistent storage via MMKV (preferred) or AsyncStorage behind a small storage module.

## Native modules
- Reach for an Expo SDK module first; then a well-maintained community module (config-plugin compatible); writing a native module (Expo Modules API) is the last resort.
- Wrap every native module behind a TS interface in `lib/` so screens never import native APIs directly; guard platform differences there (`Platform.select`), not in screens.

## Builds and environments (EAS)
- `eas.json` with `development` (dev client), `preview` (internal QA), `production` profiles; env vars per profile via EAS environment variables — secrets never in the repo.
- App config as `app.config.ts` (dynamic) reading those envs; runtime config exposed through `expo-constants` only via a typed `config.ts` module.
- OTA updates with `expo-updates`: JS-only changes ship via update channels matching the build profiles; anything touching native code requires a new build.

## Performance basics
- `FlashList` over `FlatList` for long lists; memoize row renderers; images via `expo-image` with caching; animations with Reanimated (worklets), never JS-thread `Animated` loops; avoid anonymous functions/objects in hot render paths.
