class ApplicationController < ActionController::Base
  # Allow all browsers - remove the strict modern browser filter
  # allow_browser versions: :modern

  # Require authentication for all actions by default
  before_action :require_login
  before_action :check_trial_status

  # Make these methods available in views as well
  helper_method :current_user, :logged_in?, :trial_status_info

  private

  def current_user
    # Find and cache the current logged-in user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    # Check if someone is currently logged in
    !!current_user
  end

  def require_login
    # Redirect to login if not authenticated
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page"
      redirect_to login_path
    end
  end

  def check_trial_status
    return unless logged_in?
    
    # Check if user needs to start trial
    if current_user.needs_trial_start?
      current_user.start_trial!
      flash[:success] = "Your 30-day free trial has started! Enjoy full access to all features."
    end
    
    # Show trial status flash messages only on specific pages
    if should_show_trial_flash?
      if current_user.on_trial?
        days_remaining = current_user.trial_days_remaining
        day_text = days_remaining == 1 ? 'day' : 'days'
        flash[:trial] = "⏰ Free Trial Active - #{days_remaining} #{day_text} remaining. Download the app to continue after trial."
      elsif current_user.trial_expired? && !current_user.device_downloaded?
        flash[:trial] = "⚠️ Trial Expired - Download the app to continue using Todo-it."
      end
    end
  end

  private

  def should_show_trial_flash?
    # Show trial flash messages only on pages index and settings index
    (controller_name == 'pages' && action_name == 'index') || 
    (controller_name == 'settings' && action_name == 'index')
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
