# frozen_string_literal: true

class AddDesktopApiTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :desktop_api_token_digest, :string
    add_column :users, :desktop_api_token_expires_at, :datetime
    add_index :users, :desktop_api_token_digest, unique: true
  end
end
