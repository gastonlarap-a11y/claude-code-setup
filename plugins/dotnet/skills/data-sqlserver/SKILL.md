---
name: data-sqlserver
description: EF Core 10 + SQL Server data access — DbContext lifetime, migrations, query performance, transactions and schema conventions. Use when writing any data access, entity, migration or LINQ query in a .NET project, or when standing up SQL Server locally.
---

# EF Core 10 + SQL Server

## DbContext
- Scoped lifetime via `AddDbContext` (pooled — `AddDbContextPool` — for hot services);
  never share an instance across threads or cache one in a singleton.
- Entities are internal to the data layer; endpoints map to/from records. No lazy-loading
  proxies — load explicitly (`Include`) so queries stay visible.

## Migrations are the source of truth
- Every schema change is a migration (`dotnet ef migrations add <Name>`); never
  `EnsureCreated` outside throwaway prototypes; apply with `dotnet ef database update`
  locally and `migrate` on deploy (startup migration only for single-instance apps).
- Review the generated SQL (`dotnet ef migrations script`) before it reaches a shared DB.

## Query discipline
- Reads default to `AsNoTracking()`; tracking only when you'll save changes.
- Multiple collection `Include`s → `AsSplitQuery()` (avoids row explosion).
- Project early: `Select` into the record you need instead of materializing entities.
- N+1 is the default failure mode: watch the logged SQL in dev
  (`EnableSensitiveDataLogging` locally only).
- Dapper is legitimate for measured hot paths and reporting SQL — behind the same
  repository boundary, not scattered.

## Transactions & concurrency
- One `SaveChanges` = one implicit transaction; explicit
  `Database.BeginTransactionAsync()` only for multi-step invariants.
- Concurrency: `rowversion` column + handle `DbUpdateConcurrencyException` at the
  boundary — silent last-write-wins is a decision, make it consciously.

## SQL Server conventions
- Schema per bounded area (`sales.Orders`), singular PascalCase tables mapped from
  plural DbSets explicitly; datetimes are `datetime2`/`datetimeoffset`, money is
  `decimal(19,4)` — never `float`.
- Index every FK and every column in frequent WHERE/ORDER BY; verify with the actual
  plan, not intuition.

## Local SQL Server
[references/local-sqlserver.md](references/local-sqlserver.md) — container setup for
OrbStack/Docker on any OS.
