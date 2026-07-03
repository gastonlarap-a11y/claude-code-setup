---
name: recipes
description: Curated Android integration recipes — CameraX, runtime permissions, notifications, WorkManager and deep links, Compose-first. Use when wiring one of these common integrations in an Android app; each recipe names the current recommended API and minimal pattern.
---

# Android recipes (Compose-first)

Each recipe = current recommended API + minimal wiring + official source. Confirm the latest stable API with `/research` before implementing; flag drift for `/refresh-knowledge`.

## Camera (CameraX)
- Dependencies: `camera-camera2`, `camera-lifecycle`, `camera-view` (+ `camera-compose` viewfinder). Bind use cases to lifecycle:
  `ProcessCameraProvider` → `bindToLifecycle(owner, selector, preview, imageCapture)`.
- Photo capture: `ImageCapture.takePicture(outputOptions, executor, callback)` writing via MediaStore. Analysis (QR/ML): `ImageAnalysis` + an analyzer on its own executor.
- Docs: developer.android.com/media/camera/camerax.

## Runtime permissions
- Compose: `rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted -> ... }`; check first with `ContextCompat.checkSelfPermission`.
- Rationale flow: `shouldShowRequestPermissionRationale` → explain → re-request; permanently denied → send to app settings intent.
- Ask in context; each dangerous permission also declared in the manifest.

## Notifications
- Channel (required, create at startup): `NotificationChannel(id, name, importance)` via `NotificationManager`. Build: `NotificationCompat.Builder(ctx, channelId).setSmallIcon(...).setContentTitle(...).setContentIntent(pendingIntent)`.
- Android 13+: `POST_NOTIFICATIONS` is a runtime permission (recipe above). Tap → `PendingIntent` (immutable flag) into a deep-linked destination. Push: FCM — see realtime plugin's mobile-push reference.

## Background work (WorkManager)
- `@HiltWorker class SyncWorker @AssistedInject constructor(...) : CoroutineWorker` → `doWork(): Result` (`success/retry/failure`).
- Enqueue unique: `WorkManager.enqueueUniquePeriodicWork(name, KEEP, request)` with `Constraints`. Details in the background-jobs plugin (mobile-schedulers reference).

## Deep links (App Links)
- Manifest `intent-filter` with `autoVerify=true` + host serving `/.well-known/assetlinks.json` (SHA-256 cert fingerprint).
- Navigation Compose: add `navDeepLink { uriPattern = "https://example.com/orders/{id}" }` to the destination; args arrive as route params. Test: `adb shell am start -a android.intent.action.VIEW -d "https://..."`.
