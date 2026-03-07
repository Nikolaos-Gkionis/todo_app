# Phase 3.6: Final UI Tweaks & View Switcher

## Items

1. **Breathing Room** – Add `30px` left/right and `20px` top/bottom padding to `.dashboard`.

2. **Remove Weekly Planner Heading** – Delete the "Weekly Planner" `<h1>` row entirely.

3. **Layout Split** – Week view takes 60% of viewport height; custom lists take the remaining 40%.

4. **View Switcher (FAB drawer)** – Add a "View" item to the FAB menu that opens a left-side drawer with 5 options:
   - **1** – Single day
   - **2** – Today + tomorrow
   - **3** – Three days
   - **5** – Work week
   - **7** – Full week (default)
   The dashboard controller must accept a `days` param and calculate the date range accordingly.

5. **Theme Drawer → 1 Column** – Change `.theme-modal__grid` from `grid-template-columns: 1fr 1fr` to `1fr`.

6. **Remove +NEW LIST Column** – Delete the separate `lists__column--new` block from the dashboard view. Keep the `+` tab in the tabs row but make it slightly larger and darker.

7. **Fix Failing System Test** – `spec/system/user_registration_spec.rb:4` fails because Chrome's HTML5 validation blocks empty-form submission and the "Free Trial" link text doesn't match. Update accordingly.
