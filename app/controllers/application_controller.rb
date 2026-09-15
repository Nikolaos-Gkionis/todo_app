class ApplicationController < ActionController::Base
  include FlashMessageable

  # Notebook UI (dashboard/pages/todos/settings) uses a fixed viewport with inner scroll areas.
  # Other logged-in pages (marketing, login, downloads, checkout, etc.) must keep normal document scroll.
  APP_VIEWPORT_FIXED_CONTROLLERS = %w[dashboard pages todos settings].freeze

  # Allow all browsers - remove the strict modern browser filter
  # allow_browser versions: :modern

  # Require authentication for all actions by default
  before_action :require_login
  before_action :check_trial_status
  before_action :block_expired_hosted_week!

  # Friendly redirect when session/CSRF expires (e.g. after clearing site data)
  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to app_root_path, alert: "Your session expired. Please try again."
  end

  # Make these methods available in views as well
  helper_method :current_user, :logged_in?, :trial_status_info, :can_access_app_dashboard?, :app_viewport_fixed_layout?, :github_source_url

  private

  def current_user
    # Find and cache the current logged-in user
    @current_user ||= find_user_from_session_or_remember_token
  end

  def find_user_from_session_or_remember_token
    # First try to find user from session
    if session[:user_id]
      User.find_by(id: session[:user_id])
    # If no session, try to find user from remember token
    elsif cookies.signed[:remember_token]
      user = User.find_by(remember_token: cookies.signed[:remember_token])
      if user&.remember_token_valid?
        # Auto-login user and create new session
        session[:user_id] = user.id
        user
      else
        # Invalid or expired token, clear the cookie
        cookies.delete(:remember_token)
        # Set a flash message to inform user about expired session
        flash[:notice] = "Please sign in to continue using Peponi.to."
        nil
      end
    end
  end

  def logged_in?
    # Check if someone is currently logged in
    !!current_user
  end

  def require_login
    # Redirect to login if not authenticated
    unless logged_in?
      flash_login_required
      session[:return_to] = request.original_url
      redirect_to login_path
    end
  end

  # After the hosted week on peponi.to, the account is on its way out.
  def block_expired_hosted_week!
    return unless logged_in?
    return if current_user.can_use_app?
    return if expired_hosted_week_allowed_request?

    respond_to do |format|
      format.html do
        redirect_to root_path, alert: flash_hosted_week_ended
      end
      format.turbo_stream do
        redirect_to root_path, alert: flash_hosted_week_ended
      end
      format.json { head :forbidden }
      format.any { head :forbidden }
    end
  end

  def can_access_app_dashboard?
    logged_in? && current_user.can_use_app?
  end

  def app_viewport_fixed_layout?
    logged_in? && APP_VIEWPORT_FIXED_CONTROLLERS.include?(controller_name)
  end

  def github_source_url
    "https://github.com/Nikolaos-Gkionis/todo_app"
  end

  def expired_hosted_week_allowed_request?
    case controller_path
    when "sessions", "registrations", "marketing", "contact"
      true
    when "trial"
      %w[export_data status].include?(action_name)
    else
      false
    end
  end

  def check_trial_status
    return unless logged_in?

    if current_user.needs_trial_start?
      current_user.start_trial!
      @current_user = current_user.reload
      flash_trial_started
    end

    if should_show_trial_flash?
      if current_user.on_trial?
        flash_trial_active(current_user.trial_days_remaining)
      elsif current_user.hosted_ephemeral? && current_user.trial_expired? && !current_user.grandfathered_purchaser?
        flash_trial_expired
      end
    end

    # Automatically refresh remember token when user is active (like YouTube, etc.)
    if current_user.remember_token_expires_soon?
      current_user.refresh_remember_token!
      # Update the cookie with new expiration
      cookies.signed[:remember_token] = {
        value: current_user.remember_token,
        expires: 1.year.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    end
  end

  def should_show_trial_flash?
    # Show trial flash messages only on pages index and settings index
    (controller_name == "pages" && action_name == "index") ||
    (controller_name == "settings" && action_name == "index")
  end

  def trial_status_info
    return nil unless logged_in?

    {
      on_trial: current_user.on_trial?,
      trial_expired: current_user.trial_expired?,
      device_downloaded: current_user.device_downloaded?,
      days_remaining: current_user.trial_days_remaining,
      should_show_warning: current_user.should_show_trial_warning?
    }
  end
end
