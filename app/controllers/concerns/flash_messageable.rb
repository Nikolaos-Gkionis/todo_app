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
    flash[:success] = "A week on this server has started. Export or clone the repo before it ends if you want to keep your lists."
  end

  def flash_trial_active(days_remaining)
    day_text = days_remaining == 1 ? "day" : "days"
    flash[:trial] = "#{days_remaining} #{day_text} left on this server. Export your data or run the app yourself to keep it."
  end

  def flash_trial_expired
    flash[:trial] = "This hosted week is over. Export if you still can, then run Peponi.to from source."
  end

  def flash_hosted_week_ended
    "This hosted week is over. Clone the repo and run it yourself to keep your lists."
  end

  def flash_trial_expired_redirect
    flash_error(flash_hosted_week_ended)
  end

  def flash_trial_expired_paywall
    flash_hosted_week_ended
  end

  def flash_page_limit_reached
    flash_error("You cannot create more pages on this account.")
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
    flash[:error] = "You need an active account to access this page."
  end

  def flash_invalid_token
    flash[:error] = "Invalid download token."
  end

  # Validation messages
  def flash_validation_errors
    flash.now[:alert] = "Please fix the errors below."
  end

  def flash_incorrect_password
    flash.now[:alert] = "Current password is incorrect"
  end
end
