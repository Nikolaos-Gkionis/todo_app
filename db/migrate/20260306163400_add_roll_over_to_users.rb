class AddRollOverToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :roll_over, :boolean, default: true, null: false
  end
end
