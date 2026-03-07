class AddStyleFieldsToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :bold, :boolean
    add_column :todos, :highlight_color, :string
    add_column :todos, :recurrence_rule, :string
  end
end
