class RenameProjectsToPages < ActiveRecord::Migration[8.0]
  def change
    # Rename the projects table to pages
    rename_table :projects, :pages

    # Rename the foreign key column in todos table
    rename_column :todos, :project_id, :page_id
  end
end
