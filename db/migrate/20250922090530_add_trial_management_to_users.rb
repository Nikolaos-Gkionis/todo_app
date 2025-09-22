class AddTrialManagementToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add trial management columns
    add_column :users, :trial_started_at, :datetime
    add_column :users, :trial_expires_at, :datetime
    add_column :users, :device_downloaded, :boolean, default: false, null: false
    add_column :users, :download_token, :string, limit: 255
    add_column :users, :trial_data_exported, :boolean, default: false, null: false
    
    # Add indexes for performance
    add_index :users, :trial_expires_at, name: 'idx_users_trial_expires'
    add_index :users, :download_token, name: 'idx_users_download_token'
    add_index :users, :device_downloaded, name: 'idx_users_device_downloaded'
    
    # Add constraints
    add_check_constraint :users, "trial_expires_at IS NULL OR trial_expires_at > trial_started_at", 
                        name: 'check_trial_expires_after_start'
  end
end
