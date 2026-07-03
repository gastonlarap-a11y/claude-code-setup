# Emulating Azure locally

Everything below runs in containers (OrbStack/Docker/Podman) so learning and dev cost $0.

## Azurite — Blob / Queue / Table storage
```bash
docker run -d --name azurite -p 10000:10000 -p 10001:10001 -p 10002:10002 \
  mcr.microsoft.com/azure-storage/azurite
```
Connection string: `UseDevelopmentStorage=true` (SDKs resolve it to local ports).
Full parity with the real storage SDK calls — what works here works in Azure.

## Service Bus emulator — queues/topics
Official emulator (container, config file defines queues/topics); pair it with the
`background-jobs` domain plugin patterns for consumers. Requires an SQL Server container
alongside (its metadata store) — the compose file in Microsoft's docs wires both.

## What does NOT emulate locally
- **Cosmos DB on Apple Silicon**: the vNext Linux emulator supports arm64 on Linux/
  Windows but NOT on Apple Silicon Macs (documented, unresolved). Options: free-tier
  Cosmos account in Azure, or start with SQL Server locally and introduce Cosmos when a
  real global-distribution need appears.
- **Key Vault / Managed Identity**: no emulator — local dev uses `dotnet user-secrets`
  and `DefaultAzureCredential` falls back to your `az login` developer identity. The
  code path stays identical; only the credential source changes.

## Aspire ties it together
The Aspire AppHost can declare Azurite, SQL Server and the Service Bus emulator as
resources so `dotnet run --project AppHost` starts the whole local environment with one
command and a dashboard — see `architecture` skill's aspire reference.
