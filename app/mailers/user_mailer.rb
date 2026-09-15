class UserMailer < ApplicationMailer
  default from: "Peponi.to <noreply@peponi.to>"

  def password_changed(user)
    @user = user
    @app_name = "Peponi.to"
    @change_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @user.email_address,
      subject: "Your Peponi.to password was changed"
    )
  end

  def email_changed(user, old_email)
    @user = user
    @old_email = old_email
    @app_name = "Peponi.to"
    @change_time = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: @old_email,
      subject: "Your Peponi.to email address was changed"
    )
  end

  def welcome_trial(user)
    @user = user
    @app_name = "Peponi.to"
    @trial_days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y") || "7 days from now"
    @source_url = github_source_url

    mail(
      to: @user.email_address,
      subject: "Welcome to Peponi.to"
    ) do |format|
      format.html
    end
  end

  def trial_expiring_soon(user)
    @user = user
    @app_name = "Peponi.to"
    @days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y")
    @source_url = github_source_url

    mail(
      to: @user.email_address,
      subject: "Your peponi.to week ends in #{@days_remaining} days"
    )
  end

  def trial_expiring_very_soon(user)
    @user = user
    @app_name = "Peponi.to"
    @days_remaining = user.trial_days_remaining
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y")
    @source_url = github_source_url

    mail(
      to: @user.email_address,
      subject: "Your peponi.to week ends in #{@days_remaining} days"
    )
  end

  def trial_expiring_tomorrow(user)
    @user = user
    @app_name = "Peponi.to"
    @trial_expires_at = user.trial_expires_at&.strftime("%B %d, %Y")
    @source_url = github_source_url

    mail(
      to: @user.email_address,
      subject: "Your peponi.to week ends tomorrow"
    )
  end

  def account_deleted(user_email)
    @user_email = user_email
    @app_name = "Peponi.to"
    @deletion_time = Time.current.strftime("%B %d, %Y at %I:%M %p")
    @source_url = github_source_url

    mail(
      to: @user_email,
      subject: "Your Peponi.to account has been deleted"
    )
  end

  private

  def github_source_url
    "https://github.com/Nikolaos-Gkionis/todo_app"
  end
end
