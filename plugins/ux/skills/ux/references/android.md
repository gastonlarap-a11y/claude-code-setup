# Android UX specifics (Kotlin/Compose)

## Material 3 (source: m3.material.io)
- Touch targets ≥ **48×48 dp** (visual can be smaller; extend the interactive area with
  padding — Compose `minimumInteractiveComponentSize()` enforces it).
- **Dynamic color**: support it (`dynamicLightColorScheme`/`dynamicDarkColorScheme` on
  Android 12+) with a branded fallback scheme; never hardcode colors outside the theme.
- Components carry the spec's states (pressed/focused/disabled) for free — prefer M3
  components over custom ones; customizing loses states and a11y.

## Platform behaviors that are now mandatory
- **Edge-to-edge is enforced** on Android 16 (API 36+, no opt-out): draw behind system
  bars and pad content with `WindowInsets` (Compose: `Modifier.windowInsetsPadding`,
  `contentWindowInsets` on Scaffold). Test with gesture nav AND 3-button nav.
- **Predictive back** (default on API 36+): `onBackPressed()` is no longer called — use
  `OnBackInvokedCallback` / Compose `PredictiveBackHandler`; screens should survive the
  back-preview animation without side effects.

## System integration
- Dark theme follows the system by default; both themes tested, no pure-black-on-white
  hardcodes.
- Haptics: subtle confirmation on meaningful actions (`HapticFeedbackConstants`), never on
  every tap.
- Notifications: request permission in context (API 33+), channel per purpose, deep-link
  to the relevant screen — never to the home screen.

## Accessibility
- TalkBack pass on every new screen: `contentDescription` on informative images (null on
  decorative), `Modifier.semantics` merges for composite rows, state announced
  (`stateDescription`).
- Text scales to 200% font size without truncation (`sp` for text, never `dp`).
