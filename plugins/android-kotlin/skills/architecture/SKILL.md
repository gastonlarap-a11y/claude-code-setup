---
name: architecture
description: Android app architecture — single-activity Jetpack Compose, MVVM/UDF boundaries, Hilt dependency injection and Navigation. Use when creating or restructuring Android screens, ViewModels, repositories, or DI modules.
---

# Android architecture conventions

## App structure
- Single-activity app; every screen is a composable destination. No new Activities/Fragments unless a library forces it.
- Modularize by feature when the app grows: `:app`, `:core:ui`, `:core:data`, `:feature:<name>`. Within a module, group by layer: `ui/`, `domain/` (optional), `data/`.

## UI layer (Compose + UDF)
- Unidirectional data flow: the ViewModel exposes a single immutable `UiState` (`data class` behind `StateFlow`), the UI sends events to the ViewModel; no business logic in composables.
- Collect state with `collectAsStateWithLifecycle()`. Hoist state: composables receive state + callbacks, they don't grab the ViewModel deep in the tree (pass it only at the screen root).
- Side effects only inside proper effect handlers (`LaunchedEffect`, `DisposableEffect`); one-shot events (navigation, snackbars) via a `Channel`/`SharedFlow`, never re-emittable state.

## ViewModel
- Constructor-injected (`@HiltViewModel`), exposes `StateFlow<UiState>` started with `SharingStarted.WhileSubscribed(5_000)`.
- Coroutines launch in `viewModelScope`; map exceptions to UI state (error field), never let them crash silently.

## Data layer
- Repository per domain area: exposes suspend functions / `Flow`, hides Room + Retrofit behind it. UI never touches DAOs or API services.
- Offline-first when there's a local cache: Room is the source of truth, network refreshes it.

## Hilt
- Modules by concern (`NetworkModule`, `DatabaseModule`, per-feature bindings) in `di/`; prefer `@Binds` for interface bindings, `@Provides` for builders.
- Scope deliberately: `@Singleton` for app-wide clients, unscoped otherwise. Don't inject `Context` where a narrower dependency works.

## Navigation
- Navigation Compose with type-safe (serializable) routes; a feature exposes its nav graph via an extension function on `NavGraphBuilder`. Navigation logic stays out of ViewModels — they emit events, the nav host reacts.
