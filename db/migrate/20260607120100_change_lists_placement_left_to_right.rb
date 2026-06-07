class ChangeListsPlacementLeftToRight < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE users SET lists_placement = 'right' WHERE lists_placement = 'left'
    SQL
    change_column_default :users, :lists_placement, from: "left", to: "right"
  end

  def down
    execute <<~SQL.squish
      UPDATE users SET lists_placement = 'left' WHERE lists_placement = 'right'
    SQL
    change_column_default :users, :lists_placement, from: "right", to: "left"
  end
end
