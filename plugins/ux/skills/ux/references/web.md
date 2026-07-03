# Web UX specifics (React/Next.js and any web UI)

## Core Web Vitals — "good" at the 75th percentile (source: web.dev/articles/vitals)
- **LCP** (Largest Contentful Paint) ≤ **2.5 s**: preload the hero image/font, no
  client-side data waterfall before first meaningful render (RSC/SSR help here).
- **INP** (Interaction to Next Paint) ≤ **200 ms** (replaced FID in 2024): break up long
  tasks, debounce expensive handlers, `useTransition` for non-urgent updates.
- **CLS** (Cumulative Layout Shift) ≤ **0.1**: explicit dimensions on images/embeds/ads,
  skeletons sized like the real content, no content injected above the viewport.

## Focus and keyboard
- Everything reachable and operable by keyboard alone; visible focus ring (style it,
  never `outline: none` without replacement).
- Dialogs/menus: focus moves in on open, is trapped while open, returns to the trigger on
  close (Radix/Headless UI do this — don't hand-roll).
- Route changes in SPAs: move focus to the new page's heading and announce it.

## Motion
- `@media (prefers-reduced-motion: reduce)`: disable non-essential animation (CSS-level,
  applies before paint — prefer it over JS detection). Keep opacity fades; drop
  translations/scaling/parallax.

## Responsive
- Design mobile-first; test at 320 px width. Touch targets ≥ 24×24 CSS px (WCAG 2.2
  SC 2.5.8) — but on touch-heavy pages aim for 44–48 px like native apps.
- Zoom to 200% must not break layout or hide content (WCAG 1.4.4/1.4.10).

## Semantics (a11y for free)
- Native elements first: `button`, `a`, `label`, `dialog`, `details` — ARIA only when no
  native equivalent exists; wrong ARIA is worse than none.
- One `h1` per page, heading levels don't skip; landmarks (`main`, `nav`) for screen-reader
  navigation.
