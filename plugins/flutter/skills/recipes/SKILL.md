---
name: recipes
description: Curated Flutter integration recipes — modals/bottom sheets, camera and image picking, permissions, local notifications and deep links. Use when wiring one of these common integrations in a Flutter app; each recipe names the current recommended package and minimal pattern.
---

# Flutter recipes

Each recipe = current recommended package + minimal wiring + official source. Before implementing, confirm the latest stable API with `/research` (packages here move fast); if reality differs from a recipe, flag it for `/refresh-knowledge`.

## Modal / bottom sheet
- Built-in, no package: `showModalBottomSheet(context:, isScrollControlled: true, builder:)` for sheets; `showDialog` + `AlertDialog`/`Dialog` for modals.
- Sheet content taller than half screen → `isScrollControlled: true` + `DraggableScrollableSheet`. Return values via `Navigator.pop(context, result)` and `await` the show call.
- Docs: api.flutter.dev → material/showModalBottomSheet.

## Camera & image picking
- Picking a photo/video (most cases): `image_picker` — `ImagePicker().pickImage(source: ImageSource.camera|gallery, imageQuality: 80)`. iOS needs `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` in Info.plist.
- Live preview / custom capture UI: `camera` package — `availableCameras()` → `CameraController(..., ResolutionPreset.high)` → `initialize()` → `CameraPreview(controller)`; dispose the controller. Official docs: docs.flutter.dev/cookbook (camera).

## Permissions
- `permission_handler`: `final status = await Permission.camera.request();` then branch on `status.isGranted / isPermanentlyDenied` (→ `openAppSettings()`).
- Declare the permission natively too: AndroidManifest `<uses-permission>` + Info.plist usage strings — the package doesn't add them for you.
- Ask in context (right before the feature), never all at startup.

## Local notifications
- `flutter_local_notifications`: initialize per-platform settings at startup, create the Android channel, then `show(id, title, body, details)` or `zonedSchedule` (needs `timezone` init) for scheduled ones.
- Android 13+: request `POST_NOTIFICATIONS` runtime permission (via the plugin or permission_handler). Push (remote) notifications = `firebase_messaging` — see the realtime plugin's mobile-push reference.

## Deep links
- go_router handles incoming links natively once platform config exists: Android App Links (`intent-filter` + `assetlinks.json`) / iOS Universal Links (Associated Domains + `apple-app-site-association`).
- Route parsing is just your route table — keep params validated at the screen boundary. Docs: docs.flutter.dev/ui/navigation/deep-linking.
