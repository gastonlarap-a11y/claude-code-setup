---
name: gradle
description: Gradle conventions for Android — version catalogs, Kotlin DSL, build types/flavors, common tasks and build performance. Use when editing Gradle build files, dependencies, or build configuration in an Android project.
---

# Gradle conventions (Android)

## Dependencies
- Single source of truth: `gradle/libs.versions.toml` (version catalog). No hardcoded versions or group:artifact strings inside build files — add to the catalog, reference as `libs.<alias>`.
- Kotlin DSL (`build.gradle.kts`) everywhere; no Groovy scripts.
- Use BOMs where available (Compose, Firebase, OkHttp) and let the BOM drive artifact versions.
- Shared build logic in convention plugins under `build-logic/` once more than one module repeats configuration.

## Build configuration
- `debug` and `release` build types; `release` with `isMinifyEnabled = true` + R8 rules kept next to the features that need them.
- Product flavors only for real product variants (e.g. `dev`/`prod` backends) — not for feature toggles. Flavor-specific config via `buildConfigField`/manifest placeholders, secrets injected from `local.properties`/CI env, never committed.
- Target/compile SDK pinned at the latest stable; `minSdk` changes are deliberate decisions.

## Common tasks
- `./gradlew assembleDebug` (build), `./gradlew test` (JVM tests), `./gradlew lint`, `./gradlew :app:dependencies --configuration releaseRuntimeClasspath` (dependency tree), `./gradlew dependencyUpdates` if the versions plugin is present.
- Formatting via ktlint (the global format hook runs `ktlint -F` on edited files); keep a `./gradlew ktlintCheck` task wired in CI.
- Gradle is the repo's command runner: repeated multi-step workflows become Gradle tasks (convention plugins under `build-logic/`) — no shell scripts, no prose in docs.

## Performance
- `gradle.properties`: `org.gradle.caching=true`, `org.gradle.parallel=true`, `org.gradle.configuration-cache=true` (fix violations rather than disabling it).
- Keep KAPT out: prefer KSP-compatible libraries (Room, Hilt, Moshi all support KSP).
