class SessionsController < ApplicationController
  # Allow access to login pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    # Show the login form
  end

  def create
    # Find user by email and authenticate
    user = User.find_by(email_address: params[:email_address])

    if user && user.authenticate(params[:password])
      # Login successful - create session
      session[:user_id] = user.id
      redirect_to app_root_path, notice: "Successfully logged in!"
    else
      # Login failed
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Logout - clear the session
    session[:user_id] = nil
    redirect_to root_path, notice: "Successfully logged out!"
  end
end
