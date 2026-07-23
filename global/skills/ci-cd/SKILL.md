---
name: ci-cd
description: GitHub Actions pipeline conventions for my stacks (NestJS/Node, Go, Next.js, Android, Flutter) — test/build/deploy stages, dependency caching, and Claude Code automation. Use when creating or modifying CI workflows, release pipelines, or deploy automation.
---

# CI/CD conventions (GitHub Actions)

## Pipeline shape
Standard stages, in order, failing fast:
1. **lint + typecheck** (cheap, parallel)
2. **unit tests**
3. **build** (artifact or docker image)
4. **e2e/integration** (only if the repo has them; against services from `services:` or compose)
5. **deploy** (only on `main`/tags, behind an `environment:` with protection rules)

Rules:
- Trigger on `pull_request` + `push` to `main`. Deploy jobs additionally gate on `github.ref`.
- `concurrency:` group per branch with `cancel-in-progress: true` — never waste minutes on stale commits.
- Pin action versions to a major tag (`actions/checkout@v7`), never `@main`.
- `permissions:` block at workflow level, least privilege (`contents: read` default).
- Secrets via repo/environment secrets; never echo them; prefer OIDC federation over long-lived cloud keys.
- **Secret scanning**: a `gitleaks/gitleaks-action@v3` step on every push (v2 is
  deprecated — Node 20 leaves the runners Sept 2026; needs `fetch-depth: 0` to resolve
  the pushed range; `GITLEAKS_LICENSE` only for org accounts), plus
  `gitleaks protect --staged` as a local pre-commit where the team wants it — permission
  deny rules on `.env*` are advisory; scanning is the enforced layer.

## Dependency caching per stack
- **Node/pnpm**: `actions/setup-node@v6` with `cache: pnpm` (+ corepack enable).
- **Go**: `actions/setup-go@v6` with `cache: true` (module + build cache).
- **Flutter**: `subosito/flutter-action@v2` with `cache: true`.
- **Android/Gradle**: `gradle/actions/setup-gradle@v6` (manages Gradle cache correctly).

## Docker builds in CI
- `docker/build-push-action@v7` with `cache-from/cache-to: type=gha`.
- Tag with both the git SHA and the version tag; push only from `main`/tags.

## Deploys
- Kubernetes: CI builds+pushes the image; deploy step updates the manifest tag (kustomize edit / helm upgrade) — cluster credentials only in the deploy job's environment.
- Prefer progressive delivery (staging first, prod behind a manual `environment` approval).

## Claude Code in CI
- `anthropics/claude-code-action@v1` for @claude mentions on PRs/issues; setup via `/install-github-app`.
- For automated jobs use `prompt:` + `claude_args: "--max-turns 5"` and a cheaper model — cap the blast radius and cost.
- `ANTHROPIC_API_KEY` in repo secrets.

## Review checklist
1. Does the pipeline fail fast (lint before tests before build)?
2. Caches configured for the stack's package manager?
3. `concurrency` + pinned action versions + least-privilege `permissions`?
4. Deploy only from protected refs, secrets never printed?
5. Secret scanning step (gitleaks) present?
6. Is the workflow readable by someone new to the repo (job names, comments on non-obvious steps)?
