class UserMailer < ApplicationMailer
  # Set default sender email
  default from: "Task Days <noreply@task-days.com>"

  # Purchase confirmation email with download link and install guide
  def purchase_confirmation(user, download_url, install_guide_url = nil)
    @user = user
    @download_url = download_url
    @install_guide_url = install_guide_url.presence || install_pwa_url
    @app_name = "Task Days"

    mail(
      to: @user.email_address,
      subject: "🎉 Welcome to Task Days! Your download is ready"
    )
  end

  # Password change notification
  def password_changed(user)
    @user = user
    @app_name = "Task Days"
    @change_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @user.email_address,
      subject: "🔒 Your Task Days password was changed"
    )
  end

  # Email address change notification
  def email_changed(user, old_email)
    @user = user
    @old_email = old_email
    @app_name = "Task Days"
    @change_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @old_email, # Send to old email address
      subject: "📧 Your Task Days email address was changed"
    )
  end

  # Welcome email for new trial users
  def welcome_trial(user)
    @user = user
    @app_name = "Task Days"
    @trial_days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at.strftime("%B %d, %Y")

    mail(
      to: @user.email_address,
      subject: "👋 Welcome to your 7-day Task Days trial!"
    ) do |format|
      format.html
    end
  end

  # Trial expiration warning (7 days)
  def trial_expiring_soon(user)
    @user = user
    @app_name = "Task Days"
    @days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at.strftime("%B %d, %Y")
    @download_url = Rails.application.routes.url_helpers.download_url(host: Rails.application.config.action_mailer.default_url_options[:host])

    mail(
      to: @user.email_address,
      subject: "⏰ Your Task Days trial expires in #{@days_remaining} days"
    )
  end

  # Trial expiration warning (3 days)
  def trial_expiring_very_soon(user)
    @user = user
    @app_name = "Task Days"
    @days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at.strftime("%B %d, %Y")
    @download_url = Rails.application.routes.url_helpers.download_url(host: Rails.application.config.action_mailer.default_url_options[:host])

    mail(
      to: @user.email_address,
      subject: "⚠️ Your Task Days trial expires in #{@days_remaining} days"
    )
  end

  # Trial expiration warning (1 day)
  def trial_expiring_tomorrow(user)
    @user = user
    @app_name = "Task Days"
    @trial_expires_at = user.trial_expires_at.strftime("%B %d, %Y")
    @download_url = Rails.application.routes.url_helpers.download_url(host: Rails.application.config.action_mailer.default_url_options[:host])

    mail(
      to: @user.email_address,
      subject: "🚨 Your Task Days trial expires tomorrow!"
    )
  end

  # Account deletion confirmation
  def account_deleted(user_email)
    @user_email = user_email
    @app_name = "Task Days"
    @deletion_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @user_email,
      subject: "👋 Your Task Days account has been deleted"
    )
  end

  # Download reminder for users who haven't downloaded yet
  def download_reminder(user)
    @user = user
    @app_name = "Task Days"
    @download_url = Rails.application.routes.url_helpers.download_url(host: Rails.application.config.action_mailer.default_url_options[:host])

    mail(
      to: @user.email_address,
      subject: "📱 Don't forget to download Task Days to your device!"
    )
  end
end
