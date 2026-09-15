class SessionsController < ApplicationController
  # Allow access to login pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]
  # Match registrations: trial callback must not run before credentials are applied (remember-cookie edge cases)
  skip_before_action :check_trial_status, only: [ :new, :create ]
  # Never block the login form or credential POST — paywall only applies after a session exists and hits /app
  skip_before_action :block_expired_hosted_week!, only: [ :new, :create ]
  before_action :set_marketing_nav, only: [ :new, :create ]

  def new
    # Show the login form
  end

  def create
    # Find user by email and authenticate (case insensitive)
    user = User.find_by("LOWER(email_address) = ?", params[:email_address]&.downcase)

    if user && user.authenticate(params[:password])
      # Login successful - create session
      session[:user_id] = user.id

      # Handle "Remember Me" functionality
      if params[:remember_me] == "1"
        user.remember_me!
        # Set secure cookie that expires in 1 year (like YouTube, etc.)
        cookies.signed[:remember_token] = {
          value: user.remember_token,
          expires: 1.year.from_now,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax
        }
      end

      redirect_target = after_login_redirect_path_for(user)
      redirect_to redirect_target, notice: "Successfully logged in!"
    else
      # Login failed
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Clear remember token if user is logged in
    if current_user
      current_user.forget_me!
      cookies.delete(:remember_token)
    end

    # Logout - clear the session
    session[:user_id] = nil
    redirect_to login_path, notice: "Successfully logged out!"
  end

  private

  # Avoid sending expired hosted-week users to /app.
  def after_login_redirect_path_for(user)
    return_to = session.delete(:return_to).presence
    default = hosted_week_ended?(user) ? root_path : app_root_path
    return default if return_to.blank?

    begin
      uri = URI.parse(return_to)
      base = URI.parse(request.base_url)
      return default unless uri.host == base.host
    rescue URI::InvalidURIError
      return default
    end

    return root_path if hosted_week_ended?(user) && uri.path.start_with?("/app")

    return_to
  end

  def hosted_week_ended?(user)
    user.hosted_ephemeral? && user.trial_started? && user.trial_expired? && !user.can_use_app?
  end

  def set_marketing_nav
    @marketing_nav = true
  end
end
