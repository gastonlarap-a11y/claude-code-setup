# Mobile push reference (FCM / APNs)

## Architecture
- One sender path: your backend → **FCM** (delivers to Android natively and to iOS via APNs; direct APNs only if you need APNs-only features). Server SDK: `firebase-admin`.
- Token lifecycle: app obtains a registration token → POST to your backend with the user/session → backend stores `{userId, token, platform, updatedAt}`. Refresh on token rotation callbacks; prune tokens that FCM reports as `UNREGISTERED`/invalid on send.

## Payload rules
- Keep it tiny (≤4 KB): notification title/body + a `data` map with ids (`{"type":"order_update","orderId":"..."}`); the app deep-links and fetches fresh data. Never ship sensitive content in the notification.
- `notification` messages: system-displayed (simple). `data`-only messages: app decides (needed for custom rendering/silent sync — but delivery is best-effort, throttled in background, especially iOS).

## Client side
- Android 13+: runtime `POST_NOTIFICATIONS` permission; create notification **channels** at startup (importance drives sound/heads-up). Handle foreground messages manually (`onMessageReceived` — system tray only shows background ones).
- iOS: request authorization (`UNUserNotificationCenter`), register for remote notifications; silent pushes (`content-available`) are budgeted by the OS — don't rely on them for critical sync.
- Flutter: `firebase_messaging` (+ `flutter_local_notifications` for foreground display). React Native/Expo: `expo-notifications` (+ EAS credentials handles APNs/FCM keys).

## Reliability
- Fan-out from a queue (batch `sendEachForMulticast` ≤500 tokens); handle per-token errors individually. Store notification intents server-side so a user opening the app can reconcile missed pushes — push is a hint, not a delivery guarantee.
- Topics for broadcast segments; per-user tokens for targeted sends.
