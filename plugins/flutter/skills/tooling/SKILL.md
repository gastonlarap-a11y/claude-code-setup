---
name: tooling
description: Flutter/Dart tooling — using the official Dart MCP server tools, build_runner, flavors, and dependency management. Use when running Flutter tooling, code generation, configuring flavors, or managing pub dependencies.
---

# Flutter tooling conventions

## Dart MCP server (bundled with this plugin)
This plugin registers the official Dart team MCP server (`dart mcp-server`, requires Dart SDK ≥ 3.9 / Flutter ≥ 3.35). Prefer its tools over raw shell commands when available:
- Analyzer diagnostics and fixes (project-wide, structured — better than parsing `flutter analyze` text).
- `pub` operations (add/remove/upgrade packages).
- Running tests, formatting, and hot reload against a running app.
Fall back to CLI commands if the server is unavailable (older SDK), and say so.

## Code generation (build_runner)
- One-shot: `dart run build_runner build --delete-conflicting-outputs`; during iterative work: `watch`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are committed; never hand-edited. After changing any annotated class, regenerate before running tests.

## Dependencies
- `flutter pub add <pkg>` / `flutter pub add --dev <pkg>` (keeps constraints consistent) instead of editing `pubspec.yaml` by hand.
- Caret constraints (`^x.y.z`); `flutter pub outdated` before upgrade sessions; commit `pubspec.lock` for apps.
- Vet new packages: prefer packages from `dart.dev`/`flutter.dev` publishers or Flutter Favorites; check null-safety, maintenance and platform support.

## Flavors and config
- Flavors `dev`/`prod` via `--flavor` + `--dart-define-from-file=env/<flavor>.json`; secrets never committed — env files are gitignored with a committed `env/example.json`.
- Entry points per flavor only if native config differs; otherwise a single `main.dart` reading defines.

## Linting
- `flutter_lints` (or stricter `very_good_analysis`) in `analysis_options.yaml`; fix analyzer warnings, don't ignore them — `// ignore:` requires a reason on the same line.
