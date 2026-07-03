# .NET Aspire (v13) — local orchestration

Aspire replaces hand-written docker-compose for local dev: an AppHost project declares
your services and their dependencies in C#, `dotnet run` starts everything (containers
included) with service discovery, health checks and a web dashboard (logs, traces,
metrics via OpenTelemetry). It orchestrates dev-time only — it does not generate your
production Dockerfiles. Works on OrbStack, Docker Desktop or Podman.

## AppHost shape

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var sql = builder.AddSqlServer("sql")           // SQL Server container
    .WithDataVolume()                            // survives restarts
    .AddDatabase("appdb");

var api = builder.AddProject<Projects.MyApp_Api>("api")
    .WithReference(sql)                          // injects the connection string
    .WaitFor(sql);                               // starts after SQL is healthy

builder.Build().Run();
```

The API reads the connection with `builder.Configuration.GetConnectionString("appdb")`
— same code in Azure, where the reference resolves to Azure SQL.

## When to use it
- Solution has 2+ moving parts (API + DB, + cache, + queue): yes — one `dotnet run`,
  one dashboard, no compose drift.
- Single project with a lone SQL container: the compose file in
  `data-sqlserver/references/local-sqlserver.md` is enough; add Aspire when the second
  dependency appears.

## Setup
```bash
dotnet workload update && dotnet new install Aspire.ProjectTemplates
dotnet new aspire-apphost -n AppHost      # add to existing solution
```
Verify current templates/APIs via `/research` — Aspire evolves fast.
