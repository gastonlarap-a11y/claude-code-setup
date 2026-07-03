---
name: docker-kubernetes
description: Conventions for writing Dockerfiles, docker-compose files, and Kubernetes manifests across my stacks (NestJS/Node, Go, Next.js, Flutter web). Use when creating or reviewing container images, compose setups, K8s Deployments/Services/Ingress, or Helm charts.
---

# Docker & Kubernetes conventions

## Dockerfiles — always multi-stage
- Stage 1 builds, final stage runs. Final image must contain only the artifact + runtime.
- Pin base images to a specific version tag (e.g. `node:24-alpine`, `golang:1.26-alpine`), never `latest`.
- Run as non-root: create a user and `USER` it in the final stage.
- Copy lockfile + manifest first, install deps, THEN copy source — maximizes layer cache.
- Add a `.dockerignore` mirroring `.gitignore` plus `node_modules`, `dist`, `.git`.
- Include `HEALTHCHECK` for long-running services.

Per stack:
- **Node/NestJS/Next.js**: build stage installs with the repo's package manager (`pnpm` via corepack); final stage `node:24-alpine`, `NODE_ENV=production`, only `dist` + production deps (or Next.js `output: "standalone"`).
- **Go**: build with `CGO_ENABLED=0 go build -ldflags="-s -w"`; final stage `gcr.io/distroless/static` or `scratch` + CA certs.
- **Flutter web**: build stage runs `flutter build web`; final stage `nginx:alpine` serving `build/web`.

## docker-compose (local dev only)
- Compose is for local dev/test dependencies (DB, cache, queues), not production.
- Name volumes explicitly; pin service image versions; use `healthcheck` + `depends_on: condition: service_healthy`.
- Configuration through `environment`/`env_file`, never baked into the image.

## Kubernetes manifests — non-negotiables
Every Deployment must define:
- `resources.requests` and `resources.limits` (memory limit always; CPU limit optional but requests mandatory).
- `livenessProbe` and `readinessProbe` (HTTP `/health` for APIs; readiness gates traffic, liveness restarts).
- `securityContext`: `runAsNonRoot: true`, `readOnlyRootFilesystem: true` when possible, `allowPrivilegeEscalation: false`.
- Explicit `image:` tag (immutable digest or version), `imagePullPolicy: IfNotPresent`.
- Labels: `app.kubernetes.io/name`, `app.kubernetes.io/version`, `app.kubernetes.io/component`.

Other rules:
- Config in `ConfigMap`, secrets in `Secret` (or external secret manager) — never env values hardcoded in the manifest.
- One Service per Deployment; Ingress only at the edge. Prefer `ClusterIP` internally.
- Set `replicas >= 2` + `PodDisruptionBudget` for anything user-facing; add `HorizontalPodAutoscaler` when load varies.
- Never `kubectl apply` hand-edited manifests to prod from a laptop — changes go through the CI/CD pipeline (see the `ci-cd` skill).

## Helm (when a chart is warranted)
- Use a chart only when the same app deploys to multiple environments with real variation; otherwise plain manifests + kustomize overlays are simpler.
- All environment differences live in `values-<env>.yaml`; templates stay logic-light.

## Review checklist
1. Image runs as non-root and is multi-stage?
2. Layer cache order correct (deps before source)?
3. Probes + resources present in every Deployment?
4. No secret material in image, manifest, or compose file?
5. Versions pinned everywhere (base images, chart deps)?
