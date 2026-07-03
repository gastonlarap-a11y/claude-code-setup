# Mobile background work reference

## Android — WorkManager (the default answer)
- Deferrable guaranteed work: `OneTimeWorkRequest` / `PeriodicWorkRequest` (min interval 15 min) with `Constraints` (network, charging). `CoroutineWorker` + Hilt (`@HiltWorker`) for DI.
- Uniqueness: `enqueueUniqueWork(name, ExistingWorkPolicy.KEEP/REPLACE, req)` — your dedupe layer. Chains via `beginWith().then()`.
- `Result.retry()` honors the backoff policy; `setExpedited` for user-visible-soon work. Long-running with foreground service type only when genuinely user-visible.
- Exact-time alarms (`AlarmManager.setExactAndAllowWhileIdle`) only for alarm/calendar semantics — needs the exact-alarm permission on Android 12+; everything else is WorkManager.

## iOS reality check (affects Flutter/RN designs)
- No guaranteed periodic background execution: `BGAppRefreshTask`/`BGProcessingTask` run when the OS decides. Design mobile features so background work is **opportunistic sync**, and the source of truth syncs on app open / via push (`content-available`) hints.

## Flutter
- `workmanager` package bridges WorkManager (Android) + BGTaskScheduler (iOS) for headless Dart callbacks; register the callback dispatcher at app start.
- In-app periodic work while running: plain Dart `Timer`/streams. Heavy CPU in-app: `Isolate.run`/`compute` — not a background scheduler.

## React Native / Expo
- `expo-task-manager` + `expo-background-task` for registered background tasks (same OS constraints apply); headless JS (bare RN) for FCM data messages on Android.
- Anything needing reliability (retries, exactness) belongs on the backend — mobile schedules are best-effort by platform design. Verify current Expo APIs via /research (they move fast).

## Rule of thumb
Reliable/scheduled/critical work runs server-side (see bullmq/asynq); mobile background work is cache warming, sync and notifications only.
