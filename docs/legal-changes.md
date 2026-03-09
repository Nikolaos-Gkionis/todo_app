# Legal Changes – Implementation Spec

*Consolidated summary of approved changes for implementation in Antigravity.*

---

## Overview

Two UI/UX changes have been approved and **implemented**:

1. **Task Organization (The "Drawer")** – Relocate "Someday" lists from a bottom-aligned drawer to a right-hand "Not Yet" (Future Tasks) modal.
2. **Navigation & Settings** – Relocate preferences/settings from a left-side modal to a Bottom Sheet (mobile-style) that slides up from the bottom.

---

## 1. Task Organization: Drawer → Right-hand Modal ✅

### Current vs New

| Current | New |
|--------|-----|
| "Someday" lists in a bottom-aligned drawer | "Future Tasks" in a **right-hand modal** |
| Drawer slides up from bottom of viewport | Modal slides in from the right edge |
| Risk: Bottom drawer can feel cramped, less discoverable | Right-hand modal offers more space and clearer hierarchy |

### Requirements

- **Remove:** The existing bottom-aligned drawer that displays "Someday" lists
- **Add:** A right-hand modal (or slide-over panel) labeled "Future Tasks"
- **Trigger:** Same entry point as current drawer (button, icon, or link that previously opened the drawer)
- **Content:** Same "Someday" list content; layout adapted for right-side presentation
- **Behavior:** 
  - Opens from the right edge (slide-in animation)
  - Can be closed via backdrop click, close button, or Escape key
  - Does not block the entire viewport; allows partial view of main content (optional overlay behavior)

### Technical Notes

- Consider using `<dialog>` element with `modal` attribute or a custom right-hand panel (CSS `transform` / `inset`)
- May share patterns with other modals (e.g. `calendar-picker-modal`, `app-title-dialog`, `pomodoro-done-modal`)
- Reuse existing theme variables and BEM classes for consistency

---

## 2. Navigation & Settings: Left Modal → Bottom Sheet ✅

### Current vs New

| Current | New |
|--------|-----|
| Preferences/settings in a **left-side modal** | Settings in a **Bottom Sheet** (mobile-style) **or** a **dedicated Full-page Settings view** |
| Left panel slides in or overlays | Bottom sheet slides up from bottom (option A) or full-page route (option B) |

### Implementation Options

**Option A: Bottom Sheet (Mobile-style)**

- **Behavior:** Settings open as a bottom sheet that slides up from the bottom of the viewport
- **Use case:** Good for mobile-first or compact desktop layouts; keeps user in context
- **Implementation:** 
  - Bottom sheet container with `position: fixed; bottom: 0; width: 100%;` (or max-width for desktop)
  - Slide-up animation on open
  - Drag handle at top; swipe/drag-to-close (optional)
  - Backdrop dimming; tap outside to close

**Option B: Full-page Settings View**

- **Behavior:** Settings live on a dedicated full-page route (e.g. `/app/settings` or `/settings`)
- **Use case:** Better for complex settings; more room for categories, forms, and controls
- **Implementation:**
  - Dedicated route and controller action
  - Full-page layout; navigation back to dashboard/app
  - No modal; standard page navigation (Turbo, link, or redirect)

### Requirements

- **Remove:** The existing left-side preferences/settings modal
- **Add:** Either (A) Bottom Sheet component **or** (B) Full-page Settings view
- **Content:** Same settings/preferences content; layout adapted to chosen approach
- **Navigation:** Clear entry point from app header/dashboard to access settings

### Recommendation

- **Mobile / small screens:** Prefer Bottom Sheet for quick access without leaving the app context
- **Desktop / complex settings:** Prefer Full-page Settings if the settings surface is large or has many sections
- **Hybrid:** Bottom Sheet for quick toggles; "More settings" link to full-page for advanced options (optional)

---

## 3. Iteration Directions (Implemented)

The following refinements have been applied:

### FAB Position
- **Change:** Move FAB from top-left to **bottom-left**
- **File:** `app/assets/stylesheets/application.css` (`.fab`)

### Drawer Arrow (Toggle)
- **Change:** Move the chevron from the top of the bottom section to the **right-bottom corner** of the page
- **Behavior:** Rotates appropriately (down = open, up = collapsed); floating fixed button
- **Classes:** `.lists__drawer-toggle`

### "Future Tasks" → "Not Yet"
- **Change:** Rename the section to **"Not Yet"**
- **Change:** Display as **1 single vertical list** of todos (all page todos merged into one column)
- **Removed:** Multi-column layout and per-list headers/tabs

### Visual Breaks
- **Change:** Allow users to create **visual breaks** (horizontal dividers) in the Not Yet list
- **Constraint:** Styling only — no extra functionality (dividers do not affect todos)
- **Implementation:** `is_visual_break` column on todos; "—" button in title bar adds a break
- **Migration:** `db/migrate/..._add_is_visual_break_to_todos.rb`

### No Breaking Changes
- Existing data, routes, and functionality preserved
- Pages remain in the backend; UI flattens display into one list

---

## Summary Checklist

### Task Organization (Future Tasks / Not Yet) ✅

- [x] Remove all bottom section functionality
- [x] Right-hand "Not Yet" modal (slides from right)
- [x] Single vertical list (merged from all pages)
- [x] Floating trigger at bottom-right (chevron points left when closed)
- [x] Visual breaks (styling only)
- [x] Escape and overlay click to close

### Navigation & Settings ✅

- [x] Remove left-side preferences/settings drawer
- [x] Settings Bottom Sheet (slides up from bottom)
- [x] FAB at bottom-left opens settings
- [x] Handle bar, close button, overlay
- [x] Theme, accent, font, view days, completed, roll over, account

### Layout

- [x] Week view fills remaining space (no bottom lists)
- [x] Focus mode: pomodoro footer only

---

*Run `bin/rails db:migrate` to enable visual breaks.*
