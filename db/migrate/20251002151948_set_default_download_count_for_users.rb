class SetDefaultDownloadCountForUsers < ActiveRecord::Migration[8.0]
  def change
    # Set default download_count to 0 for existing users
    User.where(download_count: nil).update_all(download_count: 0)

    # Add default value to the column
    change_column_default :users, :download_count, 0
  end
end
