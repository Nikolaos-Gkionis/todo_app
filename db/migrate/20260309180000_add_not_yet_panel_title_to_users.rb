# frozen_string_literal: true

class AddNotYetPanelTitleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :not_yet_panel_title, :string, default: "Not Yet", null: false
  end
end
