# frozen_string_literal: true

class AddIsVisualBreakToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :is_visual_break, :boolean, default: false, null: false
  end
end
