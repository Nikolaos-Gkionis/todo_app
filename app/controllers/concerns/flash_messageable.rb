module FlashMessageable
  extend ActiveSupport::Concern

  # Standard CRUD flash messages
  def flash_success(message)
    flash[:notice] = message
  end

  def flash_error(message)
    flash[:alert] = message
  end

  def flash_info(message)
    flash[:info] = message
  end

  # Resource-specific success messages
  def flash_created(resource_name)
    flash_success("#{resource_name.humanize} was successfully created.")
  end

  def flash_updated(resource_name)
    flash_success("#{resource_name.humanize} was successfully updated.")
  end

  def flash_destroyed(resource_name)
    flash_success("#{resource_name.humanize} was successfully deleted.")
  end

  # Trial-specific messages
  def flash_trial_started
    flash[:success] = "Your 7-day free trial has started! Enjoy full access to all features."
  end

  def flash_trial_active(days_remaining)
    day_text = days_remaining == 1 ? "day" : "days"
    flash[:trial] = "⏰ Free Trial Active - #{days_remaining} #{day_text} remaining. Download the app to continue after trial."
  end

  def flash_trial_expired
    flash[:trial] = "⚠️ Trial Expired - Download the app to continue using Todo-it."
  end

  # Access control messages
  def flash_trial_expired_redirect
    flash_error("Your trial has expired. Please download the app to continue creating pages.")
  end

  def flash_page_limit_reached
    flash_error("You've reached the page limit. Download the app for unlimited pages!")
  end

  def flash_todo_limit_reached
    flash_error("Free users can only add #{User::MAX_FREE_TODOS_PER_PAGE} todos per page. Upgrade to Premium for unlimited todos!")
  end

  # Authentication messages
  def flash_login_required
    flash_error("You must be logged in to access this page")
  end

  def flash_login_success
    flash_success("Successfully logged in!")
  end

  def flash_logout_success
    flash_success("Successfully logged out!")
  end

  def flash_invalid_credentials
    flash.now[:alert] = "Invalid email or password"
  end

  # Download messages
  def flash_download_required
    flash[:error] = "You need an active trial or downloaded app to access this page."
  end

  def flash_invalid_token
    flash[:error] = "Invalid download token."
  end

  def flash_payment_required
    flash[:info] = "Complete your purchase to download the app to your device."
  end

  # Validation messages
  def flash_validation_errors
    flash.now[:alert] = "Please fix the errors below."
  end

  def flash_incorrect_password
    flash.now[:alert] = "Current password is incorrect"
  end
end
