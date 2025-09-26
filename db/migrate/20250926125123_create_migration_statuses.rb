class CreateMigrationStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :migration_statuses do |t|
      t.string :migration_type, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :started_at
      t.datetime :completed_at
      t.text :metadata
      t.text :results
      t.text :error_message

      t.timestamps
    end

    add_index :migration_statuses, :migration_type, unique: true
    add_index :migration_statuses, :status
    add_index :migration_statuses, :started_at
    add_index :migration_statuses, :completed_at
  end
end
