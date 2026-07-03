# BullMQ reference (Node/NestJS)

## Setup
- BullMQ over Redis. NestJS integration: `@nestjs/bullmq` — `BullModule.forRoot` (connection) + `BullModule.registerQueue({ name })` per queue.
- One queue per domain area (`emails`, `exports`), job types within it (`add('send-confirmation', payload)`); don't create a queue per job type.

## Producers
```ts
await queue.add('send-confirmation', { orderId }, {
  attempts: 5,
  backoff: { type: 'exponential', delay: 3000 },
  removeOnComplete: { age: 3600, count: 1000 },
  removeOnFail: false,           // keep failures until DLQ/triage
  jobId: `confirm:${orderId}`,   // natural dedupe when applicable
});
```
- `jobId` dedupes at enqueue time (same id = ignored while original exists) — first idempotency layer.

## Workers (NestJS)
- `@Processor('emails')` class extending `WorkerHost`; switch on `job.name` or one processor class per queue. `concurrency` in the decorator options.
- Run workers in a **separate process/deployment** from the API (independent scaling, deploys don't drop jobs mid-flight); BullMQ sandboxed processors for CPU-heavy work.
- Throw to retry; return value stored on the job. Use `UnrecoverableError` for permanent failures (skips remaining attempts).

## Repeatable/scheduled jobs
- Job schedulers (`queue.upsertJobScheduler(id, { pattern: '0 3 * * *' }, ...)`) — singleton by design across replicas; prefer them over `@nestjs/schedule` `@Cron` on multi-replica services.

## Flows and events
- `FlowProducer` for parent/child pipelines (fan-out then aggregate). `QueueEvents` for progress/completion listeners (drive SSE/websocket progress updates).

## Ops
- No built-in DLQ: treat exhausted-failed jobs as the DLQ (`getFailed`), alert on count, replay with `job.retry()`. Dashboards: Bull Board / Taskforce.
- Redis `maxmemory-policy=noeviction` (eviction silently destroys jobs); reuse one ioredis connection per process.
