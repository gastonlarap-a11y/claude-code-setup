# Cross-platform mobile UX (Flutter / React Native)

## Respect each platform's conventions
- iOS users expect HIG behavior, Android users expect Material — don't ship one platform's
  idioms to both. Flutter: `.adaptive` constructors (`Switch.adaptive`, dialogs) or
  platform checks at the widget level; RN: `Platform.select` for navigation transitions,
  date pickers, alerts.
- Apple HIG minimum tappable area: **44×44 pt**; Material: **48×48 dp**. Use the larger
  when sharing one codebase (source: developer.apple.com/design, m3.material.io).
- Back navigation: Android hardware/gesture back must work everywhere and match the visible
  back affordance; iOS edge-swipe back must not be blocked by horizontal gestures.

## Safe areas and insets
- Every screen wrapped in safe-area handling (Flutter `SafeArea`, RN
  `react-native-safe-area-context`) — notches, punch-holes, home indicator, and Android
  edge-to-edge all break absolute positioning.
- Keyboard: content scrolls to keep the focused field visible; the keyboard never covers
  the submit button (Flutter `resizeToAvoidBottomInset`, RN `KeyboardAvoidingView`).

## Feel
- 60 fps as the bar: no sync work in build/render paths; lists always virtualized
  (`ListView.builder` / `FlatList`) with stable keys and fixed-extent items when possible.
- Touch feedback within 100 ms: ripple/highlight on every tappable; haptics for meaningful
  confirmations only.
- Gestures follow the finger (drag-to-dismiss sheets track the drag; release animates from
  current position, honoring velocity).

## Mobile-specific states
- Offline is a normal state, not an error: cache last data, show stale banner, queue
  mutations when it fits the domain.
- Permissions (camera, notifications, location): ask in context right before the feature
  needs it, with one line of why; handle "denied forever" with a settings deep-link.
- App resume: refresh stale data on foreground, never lose in-progress input.

## Accessibility
- Screen-reader pass (TalkBack/VoiceOver) per new screen: labels on tappables, grouped
  semantics for composite rows (Flutter `MergeSemantics`, RN `accessible`), dynamic type
  up to 200% without truncation.
