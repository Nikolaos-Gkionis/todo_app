class RegistrationsController < ApplicationController
  # Allow access to signup pages without authentication
  skip_before_action :require_login, only: [:new, :create]

  def new
    # Show the signup form
    @user = User.new
  end

  def create
    # Create new user with provided parameters
    @user = User.new(user_params)
    
    if @user.save
      # Signup successful - automatically log them in
      session[:user_id] = @user.id
      redirect_to app_root_path, notice: 'Account created successfully! Welcome!'
    else
      # Signup failed - show errors
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    # Only allow these parameters for security
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
