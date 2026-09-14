class UserMailer < ApplicationMailer
  # Set default sender email
  default from: "Peponi.to <noreply@peponi.to>"

  # Purchase confirmation email with download link and install guide
  def purchase_confirmation(user, download_url, install_guide_url = nil)
    @user = user
    @download_url = download_url
    @install_guide_url = install_guide_url.presence || install_pwa_url
    @app_name = "Peponi.to"

    mail(
      to: @user.email_address,
      subject: "🎉 Welcome to Peponi.to! Your download is ready"
    )
  end

  # Password change notification
  def password_changed(user)
    @user = user
    @app_name = "Peponi.to"
    @change_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @user.email_address,
      subject: "🔒 Your Peponi.to password was changed"
    )
  end

  # Email address change notification
  def email_changed(user, old_email)
    @user = user
    @old_email = old_email
    @app_name = "Peponi.to"
    @change_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @old_email, # Send to old email address
      subject: "📧 Your Peponi.to email address was changed"
    )
  end

  # Welcome email for new trial users
  def welcome_trial(user)
    @user = user
    @app_name = "Peponi.to"
    @trial_days_remaining = user.trial_days_remaining
    # strftime on nil would 500 the whole signup if trial dates were missing
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y") || "7 days from now"

    mail(
      to: @user.email_address,
      subject: "👋 Welcome to your 7-day Peponi.to trial!"
    ) do |format|
      format.html
    end
  end

  # Trial expiration warning (7 days)
  def trial_expiring_soon(user)
    @user = user
    @app_name = "Peponi.to"
    @days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y")
    @download_url = pricing_page_url

    mail(
      to: @user.email_address,
      subject: "⏰ Your Peponi.to trial expires in #{@days_remaining} days"
    )
  end

  # Trial expiration warning (3 days)
  def trial_expiring_very_soon(user)
    @user = user
    @app_name = "Peponi.to"
    @days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y")
    @download_url = pricing_page_url

    mail(
      to: @user.email_address,
      subject: "⚠️ Your Peponi.to trial expires in #{@days_remaining} days"
    )
  end

  # Trial expiration warning (1 day)
  def trial_expiring_tomorrow(user)
    @user = user
    @app_name = "Peponi.to"
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y")
    @download_url = pricing_page_url

    mail(
      to: @user.email_address,
      subject: "🚨 Your Peponi.to trial expires tomorrow!"
    )
  end

  # Account deletion confirmation
  def account_deleted(user_email)
    @user_email = user_email
    @app_name = "Peponi.to"
    @deletion_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @user_email,
      subject: "👋 Your Peponi.to account has been deleted"
    )
  end

  # Reminder for trial users who have not purchased yet
  def download_reminder(user)
    @user = user
    @app_name = "Peponi.to"
    @download_url = pricing_page_url

    mail(
      to: @user.email_address,
      subject: "Keep Peponi.to after your trial — one-time purchase"
    )
  end

  private

  # Trial emails send people to pricing (pay first), not the download page.
  def pricing_page_url
    opts = Rails.application.config.action_mailer.default_url_options || {}
    Rails.application.routes.url_helpers.pricing_url(
      **{ host: opts[:host] || "peponi.to", protocol: opts[:protocol] || "https", port: opts[:port] }.compact
    )
  end
end
