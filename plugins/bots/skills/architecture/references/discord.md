# Discord bot reference

## Two integration models
- **Gateway bot** (discord.js / discordgo): persistent WebSocket, receives events (messages, members, reactions). Needed for anything beyond slash commands. Declare only the **intents** you use; `MessageContent`, `GuildMembers`, `GuildPresences` are privileged (enable in the dev portal, justify for verification at 100+ servers).
- **HTTP-interactions bot**: Discord POSTs slash-command interactions to your endpoint; verify the Ed25519 signature (`X-Signature-Ed25519` + `X-Signature-Timestamp`) on the raw body or Discord disables the endpoint. Simpler to host (serverless-friendly) but no event stream.

## Slash commands (the primary UX)
- Register via the application commands API: global commands (propagate slowly) vs guild commands (instant — use for development).
- Interaction contract: respond within **3 seconds** — either the final reply or a deferral (`deferReply`), then follow up within 15 min via the interaction token. Ephemeral replies for user-only feedback.
- Components (buttons, selects, modals) arrive as new interactions with your `custom_id` — same 3 s rule; keep `custom_id` as a lookup key, not a data blob.

## Reliability
- Gateway: handle resume/reconnect (libraries do it — don't fight them), shard when the library tells you (~2500 guilds).
- Rate limits are per-route buckets; libraries queue automatically — never sidestep the library's REST manager with raw fetches.

## State and permissions
- Same FSM rule as any bot for multi-step flows (modals reduce the need — prefer a modal over a message back-and-forth).
- Check both the bot's guild permissions and the invoker's permissions (`default_member_permissions`) before privileged actions.
