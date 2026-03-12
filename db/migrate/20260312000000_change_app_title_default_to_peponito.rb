# frozen_string_literal: true

class ChangeAppTitleDefaultToPeponito < ActiveRecord::Migration[8.0]
  def up
    # Update existing users who have the old default to Peponito
    User.where(app_title: "Task Days").update_all(app_title: "Peponito")
    # Update the column default for new users
    change_column_default :users, :app_title, from: "Task Days", to: "Peponito"
  end

  def down
    User.where(app_title: "Peponito").update_all(app_title: "Task Days")
    change_column_default :users, :app_title, from: "Peponito", to: "Task Days"
  end
end
