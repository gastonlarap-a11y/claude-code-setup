---
name: recipes
description: Curated React Native/Expo integration recipes — camera, permissions, notifications and deep links. Use when wiring one of these common integrations in an Expo/React Native app; each recipe names the current recommended module and minimal pattern.
---

# React Native recipes (Expo-first)

Each recipe = current recommended module + minimal wiring + official source. Confirm the latest stable API with `/research` (Expo SDKs move fast); flag drift for `/refresh-knowledge`.

## Camera
- `expo-camera`: `<CameraView facing="back" ref={ref} />` + `useCameraPermissions()`; capture with `ref.current.takePictureAsync()`. Barcode scanning via `barcodeScannerSettings` + `onBarcodeScanned`.
- Just picking a photo? `expo-image-picker` (`launchCameraAsync` / `launchImageLibraryAsync`) — skip the full camera UI.
- Docs: docs.expo.dev/versions/latest/sdk/camera.

## Permissions
- Per-module hooks are the pattern: `useCameraPermissions()`, `Notifications.requestPermissionsAsync()`, etc. — each returns status + request function; branch on `granted` / `canAskAgain` (false → `Linking.openSettings()`).
- iOS usage strings and Android permissions go in `app.config.ts` via the module's **config plugin** (then `npx expo prebuild`) — not by hand-editing native projects.

## Notifications
- `expo-notifications`: request permission → `getExpoPushTokenAsync` (Expo push service) or `getDevicePushTokenAsync` (raw FCM/APNs) → send token to backend.
- Foreground display via `setNotificationHandler`; taps via `addNotificationResponseReceivedListener` → route with Expo Router (`router.push(url from data)`). Android: create channels with `setNotificationChannelAsync`.
- Local/scheduled: `scheduleNotificationAsync({ content, trigger })`. Backend fan-out: see realtime plugin's mobile-push reference.

## Deep links
- Expo Router gives file-based deep links automatically; configure `scheme` in `app.config.ts` for custom scheme + associated domains / intent filters (config plugins) for Universal/App Links.
- Incoming URL → matches the route file; validate params (zod) at the screen. Test: `npx uri-scheme open "myapp://orders/42" --ios|--android`.
- Docs: docs.expo.dev/router/advanced/deep-linking… verify current path via /research.
