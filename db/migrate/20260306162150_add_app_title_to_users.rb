class AddAppTitleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :app_title, :string, default: "TODO-IT", null: false
  end
end
