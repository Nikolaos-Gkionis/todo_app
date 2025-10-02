class SessionsController < ApplicationController
  # Allow access to login pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]

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

      redirect_to app_root_path, notice: "Successfully logged in!"
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
    redirect_to root_path, notice: "Successfully logged out!"
  end
end
