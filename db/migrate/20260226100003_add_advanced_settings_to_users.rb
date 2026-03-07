class AddAdvancedSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :accent_color, :string
    add_column :users, :font_family, :string, default: "default", null: false
  end
end
