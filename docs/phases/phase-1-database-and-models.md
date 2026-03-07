# Phase 1: Database & Models

## Goal
Prepare the database schema and ActiveRecord models for the new Horizontal Week-View and Custom Lists functionality. This establishes the foundation where a `Todo` can belong either to a specific **date** (Week View) or a **custom list** (Page), but not strictly require a `page_id`.

## Detail Steps

1. **Database Migration**
   - Generate a migration: `rails g migration MakePageIdNullableOnTodos`.
   - In the migration, alter the `todos` table to change `page_id` to allow null values:
     ```ruby
     def change
       change_column_null :todos, :page_id, true
     end
     ```

2. **Update `Todo` Model (`app/models/todo.rb`)**
   - Remove any `validates :page_id, presence: true` so the record can be saved without it.
   - Add scopes to easily fetch todos for a given week or specific page:
     ```ruby
     scope :for_date, ->(date) { where(due_date: date, page_id: nil) }
     scope :for_page, ->(page_id) { where(page_id: page_id) }
     ```

3. **Transition Logic (Drag & Drop Prep)**
   - Add methods to cleanly swap a Todo's classification:
     - `assign_to_date(date)`: Sets `due_date = date`, `page_id = nil`.
     - `assign_to_page(page_id)`: Sets `page_id = page_id`, `due_date = nil`.

4. **Testing**
   - Write or update `spec/models/todo_spec.rb` to ensure that standard user constraints hold up, and the new methods shift the properties correctly. 
   - Verify that invalid states (e.g. neither a `due_date` nor `page_id` if that is restricted, though perhaps an inbox allows both to be null) are handled correctly based on app rules.
