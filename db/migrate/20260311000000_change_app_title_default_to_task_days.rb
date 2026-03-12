# Frozen_string_literal: true

class ChangeAppTitleDefaultToTaskDays < ActiveRecord::Migration[8.0]
  def up
    # Update all existing users with the old default to "Task Days"
    User.where(app_title: "TODO-IT").update_all(app_title: "Task Days")

    # Also catch common variations (Todo-it, todo-it, etc.) in case of manual edits
    User.where("LOWER(app_title) = ?", "todo-it").update_all(app_title: "Task Days")

    # Change the default for new users
    change_column_default :users, :app_title, from: "TODO-IT", to: "Task Days"
  end

  def down
    change_column_default :users, :app_title, from: "Task Days", to: "TODO-IT"
  end
end
