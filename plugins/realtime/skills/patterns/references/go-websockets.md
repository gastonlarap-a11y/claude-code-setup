# Go realtime reference

## Library
- Default: `github.com/coder/websocket` (maintained, context-aware, minimal) or `gorilla/websocket` (battle-tested, more manual). Standard `net/http` for SSE — no library needed.

## The hub pattern (per process)
```
Hub: register/unregister chan, rooms map[string]map[*client]struct{}, broadcast chan Event
client: conn + send chan []byte (buffered) + read/write pumps
```
- **One writer goroutine per connection** (write pump draining `send`); concurrent writes to a WS connection are a data race. Reader pump enforces read limits/deadlines and routes inbound messages.
- Slow consumer policy: if a client's `send` buffer is full, drop the client (or drop-oldest for lossy feeds) — never block the hub.

## Liveness
- Server ping every ~30 s (`SetReadDeadline` extended on pong). `context.Context` from the request governs the connection lifetime; close cleanly with a status code on shutdown (hook into server graceful shutdown).

## Scaling
- Redis pub/sub or NATS between instances: hub subscribes to channels, publishes local client messages. Marshal the same envelope you use on the wire.

## SSE in Go
- `w.Header().Set("Content-Type", "text/event-stream")`, flush after each `data:` write (`http.Flusher`), send `id:` for resume, honor `Last-Event-ID` header on reconnect, and select on `r.Context().Done()` to stop.

## Testing
- `httptest.NewServer` + a real client connection; race detector mandatory (`go test -race`) — it catches the concurrent-write bugs this domain breeds.
