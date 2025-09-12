class EnsureUsersHavePremiumFalse < ActiveRecord::Migration[8.0]
  def up
    # Ensure all existing users have premium set to false
    User.where(premium: nil).update_all(premium: false)
  end
  
  def down
    # No rollback needed
  end
end
