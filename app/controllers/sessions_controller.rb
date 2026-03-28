class SessionsController < ApplicationController
  # Allow access to login pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]
  # Never block the login form or credential POST — paywall only applies after a session exists and hits /app
  skip_before_action :block_expired_trial_without_purchase!, only: [ :new, :create ]

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

      redirect_target = session.delete(:return_to).presence || app_root_path
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
end
