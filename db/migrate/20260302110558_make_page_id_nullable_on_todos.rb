class MakePageIdNullableOnTodos < ActiveRecord::Migration[8.0]
  def change
    change_column_null :todos, :page_id, true
  end
end
