# Local SQL Server 2025 in a container

Works on OrbStack (macOS), Docker Desktop, or Podman. On Apple Silicon the image is
amd64-only and runs via Rosetta — OrbStack handles this transparently; SQL Server 2025
CU1+ fixed the earlier AVX crash. (azure-sql-edge, the old arm64 workaround, was retired
Sep 2025 — do not use it.)

## docker-compose.yml

```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    platform: linux/amd64        # explicit: Rosetta on Apple Silicon
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "Local_dev_password1"   # dev-only; 8+ chars, 3 charsets
      MSSQL_PID: Developer
    ports: ["1433:1433"]
    volumes: [sqldata:/var/opt/mssql]
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"$$MSSQL_SA_PASSWORD\" -C -Q 'SELECT 1' || exit 1"]
      interval: 10s
      retries: 10
volumes:
  sqldata:
```

`docker compose up -d`, then connection string for local dev:

```
Server=localhost,1433;Database=AppDb;User Id=sa;Password=Local_dev_password1;TrustServerCertificate=True
```

## Notes
- `TrustServerCertificate=True` is local-only — Azure SQL uses encrypted connections with
  valid certs and `Authentication=Active Directory Default` instead of sa/password.
- Create the app database via EF migrations (`dotnet ef database update`), not by hand.
- Prefer the Aspire AppHost (see `architecture` skill reference) once the solution has
  more than one dependency — it replaces this compose file and adds a dashboard.
- Windows without Docker: LocalDB (`(localdb)\MSSQLLocalDB`) ships with Visual Studio and
  needs no container — same T-SQL engine, no Linux parity.
