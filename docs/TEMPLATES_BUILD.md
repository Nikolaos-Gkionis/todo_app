# Templates Build Plan

**Purpose:** Single source of truth for implementing the Templates flow (Minimal + Calendar), Advanced Settings, and related features.

---

## Summary

**Template scope: per-page.** When creating or editing a page, the user chooses **Minimal** (simple list) or **Calendar** (weekly view). Each page has its own template—like picking a dotted moleskine vs one where you draw your own weekly calendar.

**Calendar pages**: Weekly layout, omakase-style presentation, with **device date/time** and **mobile current-day focus**.

**Advanced Settings**: Accent color + 2 fonts (Serif: Lora, Sans Serif: Inter) with OS/browser fallbacks.

---

## 1. Current State Snapshot

- **Themes**: 5 themes (classic, lined, graph, vintage, dark) via body class. Stored in session and localStorage. CSS in `application.css` with `.theme-X` selectors.
- **Settings**: Single page at `settings#index` with `notebook-card` sections. Theme update via POST `/settings/theme`.
- **Pages/Todos**: Page has many todos. Todo: title, notes, completed, position. No `due_date` currently.
- **Layout**: `pages#show` renders a vertical todo list. Uses `notebook-card`, hand-drawn checkbox, sortable.

---

## 2. Data Model Changes

| Model   | Column        | Type    | Purpose                                          |
|---------|---------------|---------|--------------------------------------------------|
| pages   | template      | string  | "minimal" \| "calendar", default "minimal"      |
| todos   | due_date      | date    | nullable, for calendar day placement            |
| users   | accent_color  | string  | nullable, hex (e.g. #3b82f6)                     |
| users   | font_family   | string  | "default" \| "serif" \| "sans_serif"             |

---

## 3. Implementation Phases

### Phase 1: Foundation
- [ ] Migration: add `template` to pages
- [ ] Migration: add `due_date` to todos
- [ ] Migration: add `accent_color`, `font_family` to users
- [ ] Add template selector to `pages/new` and `pages/edit`
- [ ] Add `template` to `page_params` in PagesController

### Phase 2: Calendar View
- [ ] Branch `pages#show` on `@page.template`
- [ ] Create `_show_calendar.html.erb` partial
- [ ] Weekly columns; device date/time via JS
- [ ] Mobile: current-day focus
- [ ] Todos with `due_date` grouped by day; unscheduled at bottom

### Phase 3: Advanced Settings
- [ ] Settings section: accent color picker, font dropdown
- [ ] CSS variables for accent and font
- [ ] Add Lora and Inter font imports
- [ ] Helper for font stack (default / serif / sans_serif)

### Phase 4: Polish
- [ ] Tests for template flow
- [ ] Theme compatibility across all 5 themes
- [ ] Accessibility (labels, focus, ARIA)

---

## 4. Theme Integration Strategy

- Templates render inside the same layout; `body` theme class applies.
- Advanced settings use CSS variables (`--user-accent`, `--user-font`) that layer on top of themes.
- Font stacks: **Serif** — `'Lora', Georgia, 'Times New Roman', serif`; **Sans Serif** — `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`.

---

## 5. Build Log / Decisions

| Date       | Decision                                                                 |
|------------|--------------------------------------------------------------------------|
| 2026-02-26 | Template scope: per-page (not system-wide). Chosen at page create/edit. |
| 2026-02-26 | Fonts: Lora (serif), Inter (sans serif) with OS fallbacks.               |
| 2026-02-26 | Calendar: device date/time; mobile current-day focus.                    |
| 2026-02-26 | No separate calendar route; `pages#show` branches on `page.template`.    |
