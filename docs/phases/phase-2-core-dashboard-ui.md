# Phase 2: Core Dashboard UI & Drag/Drop

## Goal
Replace the existing notebook grid with the core application interface: a horizontal 7-day week view for dates, and a custom list view running beneath it. Implement inline creation and drag-and-drop capabilities.

## Detail Steps

1. **Dashboard View Structure**
   - Delete or repurpose `app/views/pages/index.html.erb`.
   - Create `app/views/dashboard/index.html.erb` as the new logged-in root.
   - Layout strictly using **BEM** (per `mind.md`):
     - `div.dashboard`
       - `div.dashboard__week-view` (Top Half: 7 columns for Monday - Sunday)
       - `div.dashboard__custom-lists` (Bottom Half: Columns for `Pages` custom lists).

2. **Controller Logic (`DashboardController#index`)**
   - Calculate the date range for the current week.
   - Fetch all `Todo` items where `due_date` falls within the current week.
   - Group them appropriately by day.
   - Fetch all `Page` (custom list) records belonging to the user and their associated `Todo` items.

3. **Inline Creation**
   - At the bottom of each column (for the 7 days and custom lists), embed a Turbo Frame/inline form (`form.todo-form`).
   - Using Hotwire/Turbo Streams, submitting the form creates the `Todo` async and appends it to the respective column without reloading.

4. **Drag & Drop (Stimulus)**
   - Introduce a Stimulus controller (`drag_controller.js`) wrapping a library like Sortable.js.
   - Make all 7 date columns and all custom list columns valid targets for drag loops.
   - On `"end"` event of the drag action, extract the `data-date` or `data-page-id` from the new container.
   - Make a `PATCH` request to the server to update the `Todo` record using the `assign_to_date` or `assign_to_page` methods defined in Phase 1.
