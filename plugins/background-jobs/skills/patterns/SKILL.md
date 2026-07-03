---
name: patterns
description: Background processing patterns — queues and workers, retries with backoff, idempotent consumers, the transactional outbox, scheduled jobs and dead-letter queues. Use when moving work off the request path, adding cron jobs, or debugging duplicate/lost job processing.
---

# Background jobs

## When to queue
Anything slower than ~200 ms, fallible, or third-party-bound moves off the request path: emails, exports, webhooks out, media processing, sync with external APIs. The request persists intent + enqueues; the worker does the work.

## Job design
- Payload = **ids + minimal params**, never fat objects (workers re-fetch fresh state; payloads survive schema drift).
- Name jobs by intent (`order.send-confirmation`), one handler per job type, small handlers that call the same services your API uses.
- Every job type declares: max attempts, backoff strategy, timeout, and what "poison" means for it.

## Delivery is at-least-once ⇒ consumers must be idempotent
- Natural idempotency (UPSERT, `SET status = 'sent' WHERE status = 'pending'`) when possible; else a processed-jobs table keyed by a business dedup key (unique constraint), checked/inserted in the same transaction as the effect.
- External side effects (charges, emails): pass an idempotency key to the provider.

## Retries and failure
- Exponential backoff **with jitter**; retry only retryable errors (timeouts, 5xx, deadlock) — validation/permanent errors go straight to failure, no retries.
- After max attempts → **dead-letter queue** with the error and payload; DLQ has an owner, an alert, and a documented replay path. A silent DLQ is data loss on a delay.
- Worker crash mid-job = redelivery (that's the at-least-once). Long jobs: heartbeat/lock extension or checkpointed steps.

## Transactional outbox (DB write + event/job must both happen)
Write the domain change AND an `outbox` row in one transaction; a relay polls/CDCs the table and publishes to the queue, marking rows sent. Never `save(); publish();` — the gap between them is where events are lost.

## Scheduled work (cron)
- Cron triggers must be **singleton across replicas**: use the queue's scheduler (repeatable jobs) or a distributed lock — not bare `@Cron`/OS cron on N pods.
- Scheduled job = thin trigger that enqueues real jobs (fan-out), so runs are observable and retryable like everything else.

## Observability
Track per job type: queue depth/lag, processing time, failure rate, DLQ size. Log jobId + attempt on every line.

## Per-stack tooling
[references/bullmq.md](references/bullmq.md) (Node/NestJS) · [references/asynq.md](references/asynq.md) (Go) · [references/mobile-schedulers.md](references/mobile-schedulers.md) (Android/Flutter/RN). Verify versions via `/research`.
