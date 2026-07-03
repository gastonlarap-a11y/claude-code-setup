---
name: architecture
description: Flutter app architecture — feature-first layout, state management with Riverpod, go_router navigation and platform channels. Use when creating or restructuring Flutter features, providers, routing, or native integrations.
---

# Flutter architecture conventions

## Layout (feature-first)
- `lib/features/<feature>/` with `presentation/` (widgets, controllers), `domain/` (entities, optional), `data/` (repositories, DTOs, data sources). Shared code in `lib/core/` (theme, router, networking, utils) — no business logic there.
- Barrel files only at the feature root; deep imports inside a feature are fine.

## State management (Riverpod)
- Riverpod with code generation (`@riverpod` annotations + `riverpod_generator`). If the repo already uses BLoC, follow it — never mix paradigms in one repo.
- Widgets are dumb: `ConsumerWidget` reads providers via `ref.watch(provider.select(...))` for granular rebuilds; business logic lives in `@riverpod` classes (AsyncNotifier) — not in widgets.
- Async data flows through `AsyncValue<T>`; the UI switches on `.when(data/loading/error)` — no manual isLoading booleans.
- Repositories are providers; data sources (Dio client, local DB) are injected via providers, making everything overridable in tests.

## Navigation (go_router)
- Route table in `lib/core/router/`; typed routes with `go_router_builder` where practical. Redirect logic (auth guards) centralized in the router's `redirect`, driven by a provider — not scattered in widgets.
- Navigation from controllers is an emitted state/effect the widget layer reacts to; controllers don't hold `BuildContext`.

## Immutability and models
- Domain models with `freezed` (immutable, `copyWith`, unions for states); JSON mapping with `json_serializable` in the data layer (DTO → domain mapping explicit).

## Platform channels
- Wrap every `MethodChannel` behind an abstract class + implementation in `data/`; the rest of the app never sees channel names. Handle `PlatformException` at the wrapper and translate to domain errors.
