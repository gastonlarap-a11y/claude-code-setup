---
name: ux
description: User experience fundamentals for anything a person sees or touches — required screen states, perceived performance, forms, accessibility minimums and platform conventions. Use whenever building or modifying UI in any stack (a screen, component, form, list, dialog, navigation flow), not only when the user says "UX" — apply it by default when writing frontend or mobile code.
---

# UX fundamentals

Every user-facing change is judged by these before shipping. Platform specifics live in
the references at the bottom — read the one matching the current stack.

## Required screen states
Every screen or async component ships ALL of these, not just the happy path:
- **Loading**: skeleton mirroring the final layout (not a spinner) when structure is known;
  avoid layout shift when content arrives.
- **Empty**: says why it's empty and what action creates the first item — never a blank area.
- **Error**: human message + retry action; never a raw error code or a dead end.
- **Offline/degraded**: cached data with a stale indicator beats an error page.

## Perceived performance
- Respond to input instantly: optimistic UI for mutations that rarely fail (with rollback +
  toast on failure); pending state on the triggering control, disabled while in flight.
- Never block the whole screen for a partial update; keep already-rendered content visible.
- Animate only transitions that explain something (where an element came from/went);
  respect the user's reduced-motion OS setting everywhere.

## Forms
- Validate inline on blur, re-validate on change after first error; error text next to the
  field, not only a summary. Submit shows pending and prevents double-submit.
- Never lose user input: failed submit keeps values; destructive navigation with dirty
  state warns first.

## Accessibility minimums (non-negotiable, all platforms)
- Touch/click targets: platform minimum (see references; never below WCAG 2.2's 24 px).
- Text contrast ≥ 4.5:1 (3:1 for large text) — WCAG 2.2 SC 1.4.3.
- Every interactive element has an accessible name; every input has a label; focus order
  follows visual order and is visible.
- Nothing conveyed by color alone (add icon/text).

## Platform specifics
[references/web.md](references/web.md) — Core Web Vitals, focus, responsive ·
[references/android.md](references/android.md) — Material 3, edge-to-edge, back ·
[references/mobile-cross.md](references/mobile-cross.md) — Flutter/RN, HIG, safe areas.
Verify current values via `/research` when in doubt.
