---
name: databases
description: Database conventions across my projects — schema/naming, migrations, indexing, SQL vs NoSQL choice, and per-ORM patterns (Prisma, GORM/sqlc, Room, Drift/sqflite). Use when designing schemas, writing migrations, optimizing queries, or choosing a datastore.
---

# Database conventions

## Choosing the store
- Default to **PostgreSQL** (or the project's existing SQL engine). Choose NoSQL only for a concrete reason: document flexibility with no cross-entity transactions (MongoDB), pure key-value/cache (Redis), massive write throughput with known query patterns (Cassandra/Dynamo).
- Local/desktop/mobile apps: SQLite.
- Never introduce a second database engine into a project without an explicit justification written down.

## Schema & naming (SQL)
- Tables: `snake_case`, plural (`users`, `credit_cards`). Columns: `snake_case`.
- Every table: `id` (UUIDv7 or bigint identity), `created_at`, `updated_at` (timestamptz).
- Foreign keys named `<entity>_id`, always with a real FK constraint and an explicit `ON DELETE` behavior.
- Booleans phrased positively (`is_active`, not `is_not_deleted`); prefer soft-delete via `deleted_at` timestamp only when the domain needs it.
- Money: integer minor units or `numeric` — never floats.

## Migrations — the rules that prevent disasters
- Migrations are **append-only**: never edit an applied migration; write a new one.
- Every migration must be reversible or explicitly documented as irreversible.
- Deploy-safe ordering for breaking changes (expand → migrate data → contract): add the new column/table first, backfill, switch code, drop the old one in a LATER release.
- Adding an index on a large table: `CREATE INDEX CONCURRENTLY` (Postgres) outside a transaction.
- Migrations run in CI against a scratch DB before merge.

## Indexing & query discipline
- Index every FK and every column used in frequent `WHERE`/`ORDER BY`; composite indexes ordered by selectivity/usage (equality columns first, range last).
- No `SELECT *` in application code; paginate with keyset (cursor) pagination for large sets, offset only for small admin lists.
- N+1 is the default bug: batch with joins/`IN`/dataloader patterns. Verify with query logs when touching list endpoints.
- Wrap multi-write operations in a transaction at the use-case boundary, not per-repository-call.

## Per-ORM patterns
- **Prisma (NestJS)**: schema is the source of truth; `prisma migrate dev` locally, `migrate deploy` in CI; inject `PrismaService` directly (see template-nestjs rules); use `$transaction` for multi-write.
- **Go**: prefer `sqlc` (typed SQL) or `pgx` directly for services; GORM acceptable for CRUD-heavy internal tools — but never mix both in one codebase. Migrations via `golang-migrate` or `goose`, versioned files in `migrations/`.
- **Android (Room)**: entities + DAOs per feature; `@Transaction` for multi-table reads; schema export enabled and versioned migration tests.
- **Flutter (Drift/sqflite)**: Drift for anything beyond trivial storage; schema versioned with `MigrationStrategy` and tests.

## Review checklist
1. Naming + FK constraints + timestamps present?
2. Migration reversible and deploy-safe (expand/contract)?
3. Indexes for the new query paths, and no N+1 introduced?
4. Transactions at the right boundary?
5. No floats for money, no `SELECT *`?
