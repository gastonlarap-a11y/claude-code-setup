# Telegram bot reference

## Setup
- Token from @BotFather. HTTP Bot API (`https://api.telegram.org/bot<token>/<method>`) or a framework: grammY (TS, recommended), telegram-bot-api libs (Go), python-telegram-bot.
- Webhook: `setWebhook` with `secret_token` → Telegram sends it back as `X-Telegram-Bot-Api-Secret-Token` header; reject non-matching requests. One of webhook OR getUpdates polling — never both.

## Update handling
- Dedupe by `update_id` (monotonic). ACK by returning 200 quickly; Telegram retries on failure.
- Update types you'll actually handle: `message`, `edited_message`, `callback_query` (inline buttons — must answer with `answerCallbackQuery` to stop the spinner), `inline_query`, `my_chat_member` (bot added/removed).

## UX building blocks
- Commands registered via `setMyCommands` (shows the / menu). Inline keyboards (`InlineKeyboardMarkup`) with `callback_data` (≤64 bytes — store an id, look up the rest server-side).
- Formatting: `parse_mode: "HTML"` (more robust than Markdown for user content); escape user input.
- Long operations: `sendChatAction` ("typing…"), then edit a placeholder message (`editMessageText`).

## Limits (order of magnitude — verify current values via /research)
- ~30 msg/s global, ~1 msg/s per chat (bursts allowed), ~20 msg/min per group. On 429, wait `parameters.retry_after`.
- Files: bots can send up to ~50 MB, download up to ~20 MB via `getFile` (higher with a local Bot API server).

## Testing
- Framework test harnesses (grammY has one) for handlers; a staging bot token for manual e2e. Never hardcode the token — env only.
