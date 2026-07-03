---
name: architecture
description: Bot architecture — webhook vs polling ingestion, command routing, conversation state, queued processing and platform rate limits for Telegram, Discord and WhatsApp bots. Use when building or restructuring any chat bot.
---

# Bot architecture

## Ingestion: webhook vs polling
- **Webhook** (default in production): platform POSTs updates to your HTTPS endpoint. Verify authenticity (platform-specific — see references), persist/enqueue, ACK fast (2xx in <1–2 s), process async.
- **Polling** (Telegram long-polling, dev/simple bots): no public URL needed, single consumer only. Fine for development and small internal bots; switch to webhooks for scale.
- Discord is different: events arrive over its **Gateway (WebSocket)** for most bots; HTTP interactions endpoint exists for slash-command-only bots.

## Core pipeline (any platform)
```
update → verify → dedupe (update id) → enqueue → worker: route → handle → reply via API
```
- Dedupe by the platform's update/message id (platforms redeliver on timeout).
- Never do slow work in the webhook handler; the queue decouples ACK from processing (see background-jobs plugin when enabled).

## Command routing
- One registry mapping command/intent → handler (`/start`, slash command, button callback, plain text fallback). Handlers are small functions receiving a normalized `BotContext` (user, chat, args, reply helpers) — platform SDK types stay at the edge.
- Separate: parsing (platform update → intent) / business logic (pure, testable) / rendering (reply formatting). Business logic never imports the SDK.

## Conversation state
- Stateless commands by default. Multi-step flows use an explicit finite state machine: `(chatId, userId) → { state, data, updatedAt }` persisted in Redis/DB with TTL — never in-process memory (restarts/multiple replicas lose it).
- Every flow has an escape hatch (`/cancel`) and expires stale state.

## Rate limits and reliability
- Respect platform limits with a client-side limiter + honor 429 `retry_after`. Batch/queue outbound messages per chat.
- Long tasks: reply immediately ("working on it…"), then edit/send the final message from the worker.

## Platform specifics
See [references/telegram.md](references/telegram.md), [references/discord.md](references/discord.md), [references/whatsapp.md](references/whatsapp.md). Verify current API details with `/research` — bot platforms change often.
