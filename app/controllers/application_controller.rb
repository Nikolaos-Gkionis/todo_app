class ApplicationController < ActionController::Base
  # Allow all browsers - remove the strict modern browser filter
  # allow_browser versions: :modern

  # Require authentication for all actions by default
  before_action :require_login

  # Make these methods available in views as well
  helper_method :current_user, :logged_in?

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
end
