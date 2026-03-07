# Phase 3: Theming & CSS Refit

## Goal
Shift the visual aesthetic from a heavy, notebook "card" look to a flush, highly minimal weekly planner. Convert previous skeuomorphic themes to subtle background patterns and update typography.

## Detail Steps

1. **BEM Styling Refactor**
   - Edit stylesheets in `app/assets/stylesheets/components/`.
   - Remove heavy box-shadows, borders, and margins that created the "notebook" cards.
   - Implement flat, flush flexbox/grid layouts for the columns (`.week-view__column`, `.custom-lists__list`), separating them with subtle, 1px borders or muted background contrast.
   - Ensure maximum nesting does not exceed 2 levels (`block__element--modifier`).

2. **Typography Changes**
   - Update `body` to use a modern sans-serif stack (e.g., `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto...`).
   - Leave the handwritten font behind a user setting modifier class on the body (e.g., `body--font-handwritten`).

3. **Theme Conversion**
   - Keep the existing 5 themes but adapt them to be subtle backgrounds applied at the root/body level instead of heavy textures.
   - **Classic Dotted**: Light gray dots (`radial-gradient` or subtle SVG pattern) on flat white.
   - **Lined**: Faint horizontal borders on the root background instead of card layers.
   - **Graph**: Very low opacity blueprint/grid background.
   - **Vintage**: Slightly warm, off-white (#FAFAFA -> #FDFBF7) background without card popups.
   - **Dark**: High contrast, fully flush dark mode.

4. **Mobile Responsiveness**
   - Ensure the `.dashboard__week-view` and `.dashboard__custom-lists` blocks support horizontal scrolling (`overflow-x: auto; scroll-snap-type: x mandatory;`) on small devices without breaking the layout.
