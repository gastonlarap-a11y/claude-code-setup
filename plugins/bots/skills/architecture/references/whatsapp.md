# WhatsApp bot reference (WhatsApp Business Cloud API)

## Setup
- Official path: WhatsApp Business Platform **Cloud API** (Meta-hosted). Requirements: Meta Business account, a phone number registered to the app, and (for production volume) business verification. Unofficial libraries that puppet the consumer app violate ToS — don't.
- Webhook: subscribe to `messages` field; Meta GETs a verification challenge (`hub.verify_token` echo) once, then POSTs updates. Verify `X-Hub-Signature-256` (HMAC-SHA256 of raw body with the app secret).

## The 24-hour rule (shapes everything)
- You may send **free-form messages only within 24 h of the user's last message** (the "customer service window").
- Outside the window you must use pre-approved **template messages** (HSM) — parameterized, reviewed by Meta, category-priced (marketing/utility/authentication).
- Design flows so the user's inbound message opens the window; use templates only to re-engage.

## Messages
- Inbound arrives as webhook `messages` array (text, image, interactive replies…); mark processed via `messages` status or just dedupe by `id`.
- Interactive messages: reply buttons (≤3) and list messages (≤10 rows) — prefer them over free-text parsing.
- Media: inbound media comes as an id → fetch URL via the media endpoint (URL is short-lived); outbound by id (upload first) or link.

## Delivery statuses
- Webhook also delivers `statuses` (sent/delivered/read/failed) — persist for observability; `failed` includes error codes worth alerting on (e.g. re-engagement required → needs template).

## Reliability
- ACK webhooks fast (Meta retries with backoff and can disable the subscription on sustained failures). Process via queue. Respect messaging limits (tiered by number quality/volume — verify current tiers via /research).
