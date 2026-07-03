---
name: patterns
description: Realtime communication patterns — choosing WebSocket vs SSE vs push notifications, authenticating sockets, heartbeats and reconnection, and scaling with pub/sub. Use when adding live updates, chat, presence, or push to any app.
---

# Realtime patterns

## Choosing the transport
- **SSE (Server-Sent Events)**: server→client only (feeds, progress, notifications while app open). Plain HTTP, auto-reconnect built in, works through proxies. Prefer it when the client never sends over the channel.
- **WebSocket**: bidirectional (chat, collaboration, games, live cursors). Costs: connection state on the server, explicit heartbeat/reconnect, scaling coordination.
- **Push notifications (FCM/APNs)**: reach users when the app is closed/backgrounded. Not a data channel — a tap-trigger + tiny payload; the app fetches real data on open.
- Polling every N seconds is legitimate for slow-changing data — don't add sockets for a dashboard that refreshes each minute.

## Protocol design (WS)
- Define a message envelope from day one: `{ type, payload, id?, ts }` — versionable, loggable, testable. No naked strings.
- Client→server messages that mutate state get acks (`{ type: "ack", id }`); design for at-least-once delivery client-side (dedupe by id).

## Auth
- Authenticate at handshake: cookie (same-origin web) or short-lived token in the connection URL/first message (mobile). Long-lived sockets outlive tokens — handle re-auth: server closes with a specific code on expiry, client reconnects with a fresh token.
- Authorize per channel/room at subscribe time, not just at connect.

## Liveness and reconnection
- Heartbeat both ways (ping/pong ~25–30 s); kill zombie connections after 2 missed pongs.
- Client reconnect: exponential backoff + jitter, capped; on reconnect resubscribe and **resync state** (fetch since last event id / snapshot) — the socket may have missed events. SSE gives you `Last-Event-ID` for free.

## Scaling
- More than one server instance ⇒ pub/sub backplane (Redis pub/sub or NATS): publish events by channel, each instance fans out to its local sockets. Sticky sessions only as a stopgap.
- Presence (online lists) in Redis with TTL refresh from heartbeats.

## Per-stack details
[references/nestjs-gateways.md](references/nestjs-gateways.md) · [references/go-websockets.md](references/go-websockets.md) · [references/mobile-push.md](references/mobile-push.md). Verify library versions via `/research`.
