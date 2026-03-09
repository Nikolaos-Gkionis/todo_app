# frozen_string_literal: true

class AddPaidAtToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :paid_at, :datetime

    # Backfill: users who already have device_downloaded paid before this migration
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE users SET paid_at = updated_at
          WHERE device_downloaded = true AND paid_at IS NULL
        SQL
      end
    end
  end

  def down
    remove_column :users, :paid_at
  end
end
