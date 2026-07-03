# NestJS realtime reference

## WebSocket gateways
- `@WebSocketGateway()` with the **socket.io** adapter by default; use the `ws` adapter (`@nestjs/platform-ws`) when you want raw WebSocket (mobile/non-JS clients without socket.io).
- Structure: gateway = transport edge only (parse, auth, emit); business logic lives in services the gateway injects — same boundary rule as controllers.
- Handlers: `@SubscribeMessage('event')` receives the envelope payload; return value = ack to the caller. Rooms via `socket.join(room)` / `server.to(room).emit(...)`.

## Auth
- Guards work on gateways but validate at **connection** too: in `handleConnection`, read the token (handshake auth field with socket.io; `Sec-WebSocket-Protocol` or query for ws), verify JWT, attach `socket.data.user`, disconnect on failure. Authorize room joins in the join handler.

## Scaling
- socket.io: official Redis adapter (`@socket.io/redis-adapter`) so `server.to(room)` works across instances. Raw ws: publish domain events to Redis/NATS, each instance forwards to its local sockets.
- Emit domain events from services (EventEmitter2 or the message bus) and let the gateway subscribe — services never touch sockets directly.

## SSE
- Nest supports SSE natively: `@Sse('stream')` returning an `Observable<MessageEvent>` — pair with RxJS `fromEvent`/Subject fed by domain events. Set `Last-Event-ID` handling for resume.

## Testing
- E2e: boot the app, connect a real socket.io/ws client in the test, assert emitted frames; unit-test gateway handlers as plain class methods with mocked services.
