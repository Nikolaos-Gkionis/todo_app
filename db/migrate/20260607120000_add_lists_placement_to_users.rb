class AddListsPlacementToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :lists_placement, :string, default: "right", null: false
  end
end
