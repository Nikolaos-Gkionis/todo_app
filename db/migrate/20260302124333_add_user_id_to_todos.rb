class AddUserIdToTodos < ActiveRecord::Migration[8.0]
  def up
    add_reference :todos, :user, null: true, foreign_key: true

    # Backfill user_id using the parent page
    execute <<-SQL
      UPDATE todos
      SET user_id = (SELECT user_id FROM pages WHERE pages.id = todos.page_id)
      WHERE page_id IS NOT NULL
    SQL

    # Delete any left-overs (there shouldn't be any based on previous constraints)
    execute "DELETE FROM todos WHERE user_id IS NULL"

    change_column_null :todos, :user_id, false
  end

  def down
    remove_reference :todos, :user
  end
end
