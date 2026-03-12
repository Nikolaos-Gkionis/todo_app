# frozen_string_literal: true

class ChangeAppTitlePeponitoToPeponiTo < ActiveRecord::Migration[8.0]
  def up
    # Update existing users who have "Peponito" to "Peponi.to"
    User.where(app_title: "Peponito").update_all(app_title: "Peponi.to")
    change_column_default :users, :app_title, from: "Peponito", to: "Peponi.to"
  end

  def down
    User.where(app_title: "Peponi.to").update_all(app_title: "Peponito")
    change_column_default :users, :app_title, from: "Peponi.to", to: "Peponito"
  end
end
