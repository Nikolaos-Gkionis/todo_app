class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.string :title
      t.text :notes
      t.boolean :completed
      t.references :project, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
