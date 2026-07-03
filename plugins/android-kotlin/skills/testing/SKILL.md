---
name: testing
description: Android testing conventions — JUnit + MockK unit tests, Turbine for Flows, Robolectric, Compose UI tests and Gradle test tasks. Use when writing or fixing tests in an Android project.
---

# Android testing conventions

## Layout
- JVM unit tests in `src/test/` (ViewModels, repositories, use cases, mappers) — the bulk of coverage lives here.
- Instrumented/UI tests in `src/androidTest/` — only what genuinely needs a device/emulator.
- Robolectric for JVM tests that need the Android framework (resources, Context) without an emulator.

## Unit tests (JUnit + MockK + Turbine)
- MockK for mocks: `mockk<Repo>()`, verify with `coVerify` for suspend functions; prefer relaxed mocks only for noisy dependencies you don't assert on.
- Coroutines: `kotlinx-coroutines-test` — inject dispatchers (`DispatcherProvider` pattern or constructor `CoroutineDispatcher`) so tests pass `StandardTestDispatcher`; wrap in `runTest { }`. A `MainDispatcherRule` sets `Dispatchers.Main`.
- Flows: assert with Turbine — `viewModel.uiState.test { assertThat(awaitItem()).isEqualTo(...) }`; always cancel remaining events.
- ViewModel tests cover: initial state, each event → state transition, and error mapping.

## Compose UI tests
- `createComposeRule()` (or `createAndroidComposeRule` when a real Activity matters); find nodes by semantics — add `testTag` only when text/content-description can't identify the node.
- Test the screen composable with fake state + recorded callbacks — not through the real ViewModel.

## Fakes over mocks
- For repositories used across many tests, write a hand-rolled fake (in-memory impl) in `src/test/.../fakes/` instead of re-stubbing MockK everywhere.

## Commands
- `./gradlew test` (JVM), `./gradlew connectedAndroidTest` (instrumented, needs emulator), `./gradlew lint`.
- Run JVM tests + lint before declaring done; state explicitly if instrumented tests were not run and why.
