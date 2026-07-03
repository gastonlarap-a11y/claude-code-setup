# Asynq reference (Go)

## Setup
- `github.com/hibiken/asynq` over Redis: `Client` enqueues, `Server` + `ServeMux` processes. Alternatives: **River** (Postgres-native, when you want jobs in the same DB/transaction — pairs naturally with the outbox) or NATS JetStream for streaming semantics.

## Tasks
```go
task := asynq.NewTask("order:send_confirmation",
    mustJSON(payload{OrderID: id}),
    asynq.MaxRetry(5),
    asynq.Timeout(2*time.Minute),
    asynq.Queue("default"),
    asynq.TaskID("confirm:"+id), // dedupe while pending
)
_, err := client.Enqueue(task)
```
- Type constants (`const TypeSendConfirmation = "order:send_confirmation"`) shared between producer and worker packages; payloads are small JSON structs with ids.

## Workers
```go
srv := asynq.NewServer(redisOpt, asynq.Config{
    Concurrency: 10,
    Queues: map[string]int{"critical": 6, "default": 3, "low": 1},
})
mux := asynq.NewServeMux()
mux.HandleFunc(TypeSendConfirmation, handleSendConfirmation)
```
- Handlers get `context.Context` (honor cancellation/timeout) and return error to retry; `asynq.SkipRetry` wrapped errors fail permanently.
- Separate binary (`cmd/worker/`) from the API; scale independently.

## Scheduling
- `asynq.NewScheduler` for cron entries (enqueues tasks) — run exactly one scheduler instance (or use its redis-lock guarantees); tasks fan out to normal workers.
- `client.Enqueue(task, asynq.ProcessIn(24*time.Hour))` for delayed one-offs.

## Ops
- Built-in retention: exhausted tasks land in the **archived** set = your DLQ; alert on its size, requeue via CLI/Web UI (`asynqmon`).
- `asynq.ErrDuplicateTask` from TaskID collisions is expected — treat as success when semantics allow.
