# Calendar Modal – Implementation Spec

*For review before implementation.*

---

## Overview

Replace the current « ‹ TODAY › » navigation with a **calendar icon** that opens a **modal**. The modal lets users pick a day to navigate to; it includes a "Today" shortcut and a clickable month grid.

---

## Current vs New

| Current | New |
|--------|-----|
| « ‹ TODAY › » links inline in header | Single **calendar icon** (📅 or SVG) |
| Click TODAY → `/app` | Click icon → **modal opens** |
| Click ‹ › → `/app?start_date=...` | In modal: pick date or click Today → navigate → modal closes |

---

## UI Design

### 1. Header change
- **Remove:** The entire `« ‹ TODAY › »` block from `dashboard__header-right`
- **Add:** One button/icon (calendar SVG) with `aria-label="Pick a date"` or `title="Pick a date"`
- Clicking the icon opens the calendar modal

### 2. Modal structure
- `<dialog>` element (native HTML modal, same pattern as app-title-dialog, pomodoro-done-modal)
- **Header:** "Pick a date" (or similar)
- **Body:**
  - **"Today" link/button** at the top – navigates to current date, closes modal
  - **Month grid** below:
    - Month/year header with ‹ › to change month
    - 7-column grid (Sun–Sat or Mon–Sun, match app locale)
    - Each cell = one day; clickable
    - Visual highlight for:
      - Today
      - The selected `start_date` (if in view)
    - Optional: small dot/indicator if the day has todos (can be phase 2)
- **Footer:** Close button or "Cancel" (closes without navigating)

### 3. Behaviour
- **Click "Today":** Navigate to `app_root_path` (no `start_date`) → Turbo reload → modal closes
- **Click a date:** Navigate to `app_root_path(start_date: YYYY-MM-DD)` → Turbo reload → modal closes
- **Click ‹ › (month nav):** Change displayed month only (no navigation)
- **Click backdrop or Cancel:** Close modal, no navigation
- **Escape key:** Close modal (native `<dialog>` behaviour)

---

## Technical Approach

### Files to touch
1. **`app/views/dashboard/index.html.erb`**
   - Replace `« ‹ TODAY › »` block with calendar icon button
   - Add `<dialog id="calendar-picker-modal">` with modal content
   - Minimal JS to open dialog: `onclick="document.getElementById('calendar-picker-modal').showModal()"`
   - Month grid can be rendered server-side (Rails) for the initial month, or built in JS for client-side month switching

2. **`config/routes.rb`**
   - No changes; reuse `/app` with `start_date` param

3. **`app/controllers/dashboard_controller.rb`**
   - No changes; already handles `start_date`

4. **`app/assets/stylesheets/application.css`**
   - Add BEM classes for `.calendar-modal`, `.calendar-modal__grid`, `.calendar-modal__today`, `.calendar-modal__day`, etc.
   - Reuse existing theme variables

### Modal content options

**Option A: Server-rendered month**
- Controller passes `@calendar_month`, `@calendar_dates` for the displayed month
- View renders the grid once
- Month ‹ › would need a new request or Turbo frame to update

**Option B: Client-side calendar**
- Modal body is mostly empty or has a simple structure
- Stimulus controller (e.g. `calendar_picker_controller.js`) builds the month grid in JS
- Month ‹ › updates the grid without page reload
- Links: `<a href="/app?start_date=2025-03-15" data-turbo-action="replace">15</a>` etc.

**Option C: Hybrid**
- Initial month rendered by Rails (matches `@start_date`)
- Month ‹ › triggers a Turbo Frame request to a lightweight endpoint that returns just the grid HTML for the new month

**Recommendation:** Option B (client-side) for simplicity: no new routes, full control over month switching, and clean links for navigation.

---

## Stimulus controller (if Option B)

```
calendar_picker_controller.js
├── connect(): Build initial grid for current month (or @start_date)
├── displayMonth(date): Render grid for given month
├── monthPrev() / monthNext(): Change displayed month
├── Values: currentMonth (Date), startDate (from data attribute)
└── Targets: grid container, month label, today button
```

---

## Accessibility
- `aria-label` or `title` on calendar icon
- Focus trap inside modal when open (or rely on native `<dialog>`)
- Escape to close
- Semantic structure (e.g. table or grid role for the calendar)

---

## Summary Checklist

- [ ] Replace « ‹ TODAY › » with calendar icon
- [ ] Add `<dialog id="calendar-picker-modal">` with modal structure
- [ ] "Today" link → `/app`, closes modal
- [ ] Month grid with clickable dates → `/app?start_date=...`, closes modal
- [ ] Month ‹ › to change displayed month
- [ ] Highlight Today and current start_date in grid
- [ ] Style modal to match app themes
- [ ] (Optional) Todo indicators on dates

---

*Ready for your feedback before implementation.*
