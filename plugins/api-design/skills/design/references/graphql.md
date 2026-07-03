# GraphQL reference

## Schema design
- Schema-first or code-first per repo convention, but the schema is the contract: review schema diffs like API diffs.
- Nullable by default only where absence is meaningful; make lists and IDs non-null (`[Item!]!`, `ID!`).
- Connections (Relay style: `edges { node, cursor }, pageInfo`) for any paginated list — don't invent ad-hoc pagination per field.
- Mutations: one input object (`input CreateOrderInput`), one payload type per mutation with `userErrors: [UserError!]!` for domain failures; transport errors stay in the GraphQL `errors` array.

## N+1 discipline
- Every resolver that loads by parent ID goes through a DataLoader (batch + cache per request). Adding a resolver without a loader on a hot path is a review blocker.

## Safety limits
- Enforce depth limit, complexity/cost limit, and disable introspection in production for private APIs.
- Persisted queries (or at least an allowlist) for mobile clients: smaller payloads, no arbitrary query surface.

## Versioning
- Don't version the endpoint; evolve the schema: add fields freely, deprecate with `@deprecated(reason:)`, remove only after usage telemetry shows zero clients.

## Caching
- Response caching is per-field hard; rely on client normalized caches (Apollo/urql/TanStack) + server-side caching at the data layer. Use `@cacheControl` hints only if the gateway honors them.
