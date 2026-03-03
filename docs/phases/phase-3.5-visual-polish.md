# Phase 3.5: Visual Polish & UX Wrap-up

## Goal
Close the gap between the current app and the reference screenshots. Fix broken interactions, refine layout, navigation, and typography to achieve a 99% match with the flat, minimal design.

## Issues to Fix

### 1. Add Task Broken
The turbo stream response (`create.turbo_stream.erb`) references old CSS classes (`.week-view__column`, `.custom-lists__list`) that were renamed. The form clear script can't find the container, causing the input not to reset and potentially erroring.

### 2. Full-Width / Full-Height Layout
The dashboard should stretch to use all available screen width and height. Remove `max-width` constraint; let columns fill the viewport.

### 3. Font Alignment & Concise Content
- Ensure consistent sans-serif font throughout the app interior (no leftover handwritten font references).
- Registration form still uses `Gloria Hallelujah` inline styles — remove.
- Tighten spacing and make labels/headers concise.

### 4. FAB Button → Right Side, No Background
- Move the hamburger button from bottom-left to **bottom-right**.
- Remove the round black circle background. Show just the hamburger icon (dark gray, no container).

### 5. Bottom Sheet Behaviour
- When the bottom sheet opens, **hide the FAB** and show an **× close** button in its place (or inside the sheet).
- **Centre-align** all items inside the bottom sheet.
- Same for the desktop nav bar.

### 6. Theme & Extra Settings → Left Drawer
- Instead of a centred modal, the theme selector (and any future extra settings) should **slide in from the left** as a side drawer panel.
