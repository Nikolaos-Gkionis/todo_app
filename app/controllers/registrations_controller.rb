class RegistrationsController < ApplicationController
  # Allow access to signup pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]
  skip_before_action :check_trial_status, only: [ :new, :create ]

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

      # Start trial for new user
      @user.start_trial!

      # Send welcome email
      UserMailer.welcome_trial(@user).deliver_now

      redirect_to app_root_path, notice: "Account created successfully! Your 7-day free trial has started. Welcome!"
    else
      # Signup failed - show errors
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    # Only allow these parameters for security
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end
end
