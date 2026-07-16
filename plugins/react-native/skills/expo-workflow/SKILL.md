---
name: expo-workflow
description: Day-to-day Expo workflow — dev client, prebuild, EAS build/submit/update commands and the official expo plugin. Use when running, building, updating, or releasing an Expo/React Native app.
---

# Expo workflow

## Companion plugin
For deeper Expo automation (EAS builds, submissions, doctor checks), enable the official plugin alongside this one in the project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "react-native@dev-plugins": true,
    "expo@claude-plugins-official": true
  }
}
```

## Daily development
- Start: `npx expo start` (add `--dev-client` when the app uses custom native code). Clear cache with `--clear` only when diagnosing bundler weirdness, not by default.
- After adding a library with native code: `npx expo install <pkg>` (version-aligned with the SDK — always prefer it over npm/pnpm add for RN packages), then rebuild the dev client (`eas build --profile development`).
- Keep native projects generated: `npx expo prebuild --clean` regenerates `ios/`/`android/` from `app.config.ts` + config plugins; never hand-edit generated native projects in managed apps.
- Health check when things break: `npx expo-doctor`.

## Upgrades
- SDK upgrades are deliberate tasks: `npx expo install expo@latest && npx expo install --fix`, then run `npx expo-doctor`, rebuild dev clients, and re-run the test suite. Read the SDK release notes (latest stable, official blog) first.

## Release flow (EAS)
1. `eas build --profile production --platform all`
2. `eas submit` per store (credentials managed by EAS).
3. JS-only follow-ups: `eas update --channel production --message "<conventional message>"`.
- Never ship an OTA update that includes native-dependency changes; when in doubt, compare with `npx expo install --check` and cut a new build.
- Version bumps follow the repo's convention (`app.config.ts` `version` + `runtimeVersion` policy); note the runtime version implications of any native change.
