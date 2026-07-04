---
name: tooling
description: Go tooling conventions — golangci-lint configuration, module hygiene, code generation, Makefile as command runner, OpenAPI for HTTP services and release practices. Use when setting up linting, managing go.mod, generating code, documenting an API, or preparing releases in a Go project.
---

# Go tooling conventions

## Linting
- `golangci-lint` is the single lint entrypoint (`golangci-lint run`). Baseline enabled linters beyond defaults: `errcheck`, `govet`, `staticcheck`, `revive`, `gosec`, `errorlint`, `sqlclosecheck`, `bodyclose`, `noctx`.
- Config lives in `.golangci.yml` at the repo root; fix findings, don't blanket-disable — a `//nolint:<linter> // reason` needs the reason.

## Modules
- `go mod tidy` after any dependency change; commit `go.mod` + `go.sum` together.
- Pin the Go version in `go.mod` (`go 1.x`) and keep CI on the same version.
- Upgrades: `go get -u=patch ./...` routinely; major-version bumps (`/v2`) are deliberate changes with a migration note in the PR.
- Vendor only if the deployment environment requires it.

## Code generation
- Generated code is committed, marked with the standard `// Code generated ... DO NOT EDIT.` header, and regenerated via `go generate ./...` — never hand-edited.
- Preferred generators: `sqlc` for queries, `mockgen`/`moq` for interface mocks (only interfaces the tests actually need), `stringer` for enums.
- CI verifies generation is current: regenerate + `git diff --exit-code`.

## OpenAPI (HTTP services)
- No single standard: spec-first with `oapi-codegen` (the spec is the contract; handlers and
  types generated, pairing with the codegen rules above) or code-first via `swaggo`
  annotations / a spec-generating framework (e.g. huma).
- Prefer spec-first for new services; verify current tools and versions via `/research`.

## Command runner
- Repo commands centralize in the root `Makefile` — new repeated commands become targets
  (`run` `build` `test` `lint` `generate`), not prose in docs.

## Build and release
- Reproducible builds: `CGO_ENABLED=0`, `-trimpath`, version injected via `-ldflags "-X main.version=..."`.
- Cross-compile via `GOOS`/`GOARCH` matrix in CI, not on laptops; releases through GoReleaser when the project ships binaries.
