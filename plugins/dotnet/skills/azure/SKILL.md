---
name: azure
description: Azure for .NET services — choosing compute (Container Apps vs App Service vs Functions), Azure SQL, Key Vault with managed identity, and CI/CD to Azure. Use when deploying, hosting, securing or wiring a .NET app to any Azure service, and when emulating Azure locally.
---

# Azure for this stack

## Compute choice
- **Container Apps**: default for containerized APIs/workers — scale-to-zero, revisions,
  Dapr if needed. You already know containers; this is the least new surface.
- **App Service**: fine for a single always-on web app without container pipeline needs.
- **Functions**: event-driven, per-invocation billing (queues, timers, blobs) — not for
  hosting your main API.

## Identity is the security model
- **Managed Identity + `DefaultAzureCredential` everywhere**; connection strings with
  passwords are the legacy path. Azure SQL: `Authentication=Active Directory Default`.
- Secrets that must exist live in **Key Vault**, read through configuration
  (`AddAzureKeyVault`) — code never knows it's a vault. Local dev uses user-secrets
  (`dotnet user-secrets`), never committed files.
- Grant roles at the narrowest scope (resource, not subscription); the app's identity
  gets exactly the roles it uses.

## Data
- **Azure SQL Database** = same engine as local SQL Server 2025 container, so local dev
  mirrors prod. Serverless tier for learning/spiky loads (auto-pause), provisioned for
  steady enterprise traffic.
- Blob/Queue/Table → the storage SDKs against Azurite locally (see reference).

## Deploy
- GitHub Actions with **OIDC federated credentials** (`azure/login`, no stored service
  principal secret): build → test → `az containerapp update` (or `azure/webapps-deploy`).
- Infra as code from day one: Bicep in the repo (`infra/`), deployed by the same
  pipeline — portal changes don't survive; consult the `ci-cd` skill for pipeline shape.

## Local emulation
[references/local-azure.md](references/local-azure.md) — Azurite, Service Bus emulator,
and what cannot be emulated on Apple Silicon. Verify service specifics via `/research`.
