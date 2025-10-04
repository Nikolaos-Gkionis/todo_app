class UserMailerPreview < ActionMailer::Preview
  def welcome_trial
    user = create_test_user
    user.trial_started_at = 1.day.ago
    user.trial_expires_at = 6.days.from_now
    UserMailer.welcome_trial(user)
  end

  def trial_expiring_soon
    user = create_test_user
    user.trial_started_at = 4.days.ago
    user.trial_expires_at = 3.days.from_now
    UserMailer.trial_expiring_soon(user)
  end

  def trial_expiring_tomorrow
    user = create_test_user
    user.trial_started_at = 6.days.ago
    user.trial_expires_at = 1.day.from_now
    UserMailer.trial_expiring_tomorrow(user)
  end

  def trial_expiring_very_soon
    user = create_test_user
    user.trial_started_at = 6.days.ago
    user.trial_expires_at = 6.hours.from_now
    UserMailer.trial_expiring_very_soon(user)
  end

  def purchase_confirmation
    user = create_test_user
    UserMailer.purchase_confirmation(user, "https://example.com/download")
  end

  def download_reminder
    user = create_test_user
    UserMailer.download_reminder(user)
  end

  def account_deleted
    UserMailer.account_deleted("test@example.com")
  end

  def email_changed
    user = create_test_user
    UserMailer.email_changed(user, "old@example.com")
  end

  def password_changed
    user = create_test_user
    UserMailer.password_changed(user)
  end

  private

  def create_test_user
    # Create a user in memory for preview purposes
    user = User.new(
      email_address: "test@example.com",
      name: "Test User",
      password: "password123"
    )
    
    # Set trial dates manually for preview
    user.trial_started_at = 1.day.ago
    user.trial_expires_at = 3.days.from_now
    
    user
  end
end
