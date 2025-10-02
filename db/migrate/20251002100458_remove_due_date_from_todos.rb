class RemoveDueDateFromTodos < ActiveRecord::Migration[8.0]
  def change
    remove_column :todos, :due_date, :date
  end
end
