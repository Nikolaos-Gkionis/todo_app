# Implementation Plan (Redesign Plan)

## Goal Summary
Transform the application from a "Notebook-based" layout into a highly minimal, aesthetic **Weekly Planner** inspired by TeuxDeux. We will introduce a horizontal week-view with custom lists below it. 

We will firmly retain the **Offline-First / Zero-Cloud** narrative and core privacy features, but reframe the marketing pitch to highlight extreme simplicity, reduced mental clutter, and a minimal aesthetic without heavy notebook borders or textures.

## Proposed Changes

### Data Model Strategy
- #### [MODIFY] db/migrate/xxxx_make_page_id_nullable_on_todos.rb
  - We need to create a migration to make `page_id` nullable on `todos`. 
  - **Week View (Dates)**: Todos assigned to a specific date will have a `due_date` and `page_id: null`.
  - **Custom Lists (Pages)**: Todos assigned to a custom list will have a `page_id` and typically `due_date: null`.
- #### [MODIFY] app/models/todo.rb
  - Update validations (remove `presence: true` from `page_id`).
  - Add logic to handle switching between a Date column and a Page column (drags).

### UI/UX & Theming Strategy
- #### [DELETE] app/views/pages/index.html.erb
- #### [NEW] app/views/dashboard/index.html.erb (or similar root logged-in view)
  - Replace the current grid of notebook cards.
  - **Top Half**: Horizontal layout of 5 to 7 date columns (e.g., Monday through Sunday).
  - **Bottom Half**: Horizontal layout of Custom Lists (currently `Pages`).
  - **Adding Todos**: Inline text inputs at the bottom of each column/list instead of separate forms.
- #### [MODIFY] app/assets/stylesheets/application.css (or components)
  - The heavy "card" look will be removed. Backgrounds will become fully flush.
  - The existing 5 themes (Classic Dotted, Lined, Graph, Vintage, Dark) will be converted into **dimmed, subtle background patterns**.
  - Switch the default font to a clean, highly readable font family.
  - Retain the current handwritten font **only as an optional user setting**.

### Marketing Pages Rewrite
- #### [MODIFY] app/views/marketing/landing.html.erb
  - **Visuals**: Replace mockup HTML with the new minimal columned week-view.
  - **Copy**: Shift the narrative from "Todo pages that feel hand-crafted" to "The simplest calendar-based todo app. 100% Yours."
  - Highlight mental clarity and zero-cloud (no subscriptions, extreme privacy).
- #### [MODIFY] other marketing pages ([pricing.html.erb](file:///Users/laptop/Documents/GitHub/todo_app/app/views/marketing/pricing.html.erb), [why.html.erb](file:///Users/laptop/Documents/GitHub/todo_app/app/views/marketing/why.html.erb))
  - Ensure the minimal aesthetic and messaging match the redesigned landing page.

## Verification Plan

### Automated Tests
- Run existing test suites to ensure model changes do not break basic user creation and constraints:
  ```bash
  bundle exec rspec spec/models/
  ```
- Write new system tests (`spec/system/todos_view_spec.rb` or similar) to verify inline creation of todos in date columns and page columns. Run via:
  ```bash
  bundle exec rspec spec/system/
  ```

### Manual Verification
1. Start the server locally:
   ```bash
   bin/dev
   ```
2. Navigate to `http://localhost:3000` to verify the rewrite of the marketing pages, ensuring visual alignment with the new minimal aesthetic.
3. Sign up/Log in and verify the 7-day horizontal week layout and custom lists below.
4. Interact with the UI: create a new todo in a specific day, drag it to another day, and drag it to a custom list.
5. Go to Settings and toggle the 5 themes (ensure they are now "dimmed" backgrounds without card borders) and toggle the handwritten font option.

## Expected Time Estimation
- **Phase 1: Database & Models**: ~2 hours
- **Phase 2: Core Dashboard UI & Drag/Drop**: ~8-10 hours
- **Phase 3: Theming & CSS Refit**: ~4-5 hours
- **Phase 4: Marketing Rewrite**: ~4-5 hours
**Total Estimated Build Time**: ~18-22 hours.
