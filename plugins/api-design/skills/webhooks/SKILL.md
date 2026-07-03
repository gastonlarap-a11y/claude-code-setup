---
name: webhooks
description: Webhook design for producers and consumers — signing and verification, retries, ordering, idempotent processing and operational endpoints. Use when emitting webhooks from a service or consuming third-party webhooks.
---

# Webhooks

## Producing webhooks
- Payload: event envelope `{ id, type, createdAt, apiVersion, data }`. `id` is unique per event (consumer dedup key); `type` is namespaced (`order.paid`).
- Sign every delivery: HMAC-SHA256 over `timestamp + "." + rawBody` with a per-endpoint secret; send as `X-Signature: t=...,v1=...`. Reject if timestamp older than ~5 min (replay window).
- Delivery: POST with tight timeout (5–10 s); success = 2xx only. Retry on anything else with exponential backoff + jitter over hours/days; after exhaustion, park in a dead-letter list visible to the customer and (optionally) auto-disable chronically failing endpoints.
- Don't guarantee order — consumers must not assume it. Include enough state in `data` (or send fat events with current resource state) so late/out-of-order events resolve correctly.
- Dispatch from an outbox/queue, never inline in the request path of the triggering operation.

## Consuming webhooks
- Verify the signature against the RAW request body (frameworks must expose rawBody — e.g. Fastify `rawBody: true`) before parsing; constant-time compare.
- Respond 2xx immediately after persisting the event; process asynchronously (queue). Slow handlers cause producer retries → duplicates.
- Idempotent processing: store processed event `id`s (unique constraint) and skip repeats; handle out-of-order by checking resource state/timestamps, not assuming sequence.
- Treat the webhook as a hint when the producer offers a read API: on doubt, re-fetch the resource ("trust but verify").

## Operations
- Producer side: per-endpoint delivery log (status, attempts, next retry) + manual redelivery. Consumer side: alert on sustained verification failures (secret rotation gone wrong) and on queue lag.
- Local development: tunnel (e.g. cloudflared/ngrok) or provider CLI forwarding (e.g. `stripe listen`) — never test signature code against synthetic unsigned payloads only.
