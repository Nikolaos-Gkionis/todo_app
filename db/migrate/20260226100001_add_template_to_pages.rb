class AddTemplateToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :template, :string, default: "minimal", null: false
  end
end
