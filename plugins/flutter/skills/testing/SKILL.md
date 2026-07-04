---
name: testing
description: Flutter testing conventions — unit tests, widget tests, golden tests and integration_test setup. Use when writing or fixing tests in a Flutter project.
---

# Flutter testing conventions

## Layers
- `test/` mirrors `lib/` structure. Unit tests for controllers/repositories/mappers; widget tests for every screen and reusable widget; `integration_test/` for the few critical device flows; goldens for visual-regression-sensitive widgets.

## Unit tests
- Riverpod: build a `ProviderContainer` with `overrides` (fake repositories), read the provider, assert emitted states; `addTearDown(container.dispose)`.
- Mocks with `mocktail` (no codegen); prefer hand-written fakes for repositories reused across many tests.
- Async states: assert the full `AsyncValue` progression (loading → data / error), not just the final value.

## Widget tests
- `pumpWidget` wrapping the widget in `ProviderScope(overrides: [...])` + `MaterialApp` (or the app router harness for navigation-dependent screens).
- Find by type/text/semantics; `Key`s only when structure is ambiguous. Use `tester.pumpAndSettle()` after interactions — with timeout awareness for infinite animations (pump fixed durations instead).
- Fake time-dependent behavior (`fakeAsync`, injected clocks); tests must be deterministic.

## Golden tests
- Goldens for the design-system widgets and complex screens, under fixed surface size + font loading (`loadAppFonts`); regenerate deliberately with `flutter test --update-goldens` and review the diff like code.

## Integration tests
- `integration_test/` + `IntegrationTestWidgetsFlutterBinding`; run on a device/emulator (`flutter test integration_test`). Cover launch, auth, and the primary happy path only.

## Commands
- `flutter analyze` + `flutter test` before declaring done; report real output. Coverage: `flutter test --coverage`.
- Repo commands centralize in a `Makefile` (`make test`/`analyze`/`build`) or melos scripts when `melos.yaml` exists — check the README and extend those instead of raw invocations.
