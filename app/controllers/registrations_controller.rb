class RegistrationsController < ApplicationController
  # Allow access to signup pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]
  skip_before_action :check_trial_status, only: [ :new, :create ]
  skip_before_action :block_expired_trial_without_purchase!, only: [ :new, :create ]
  before_action :set_marketing_nav, only: [ :new, :create ]

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

      # Queue the welcome email so Brevo cannot 500 the signup.
      # Production already failed here with Brevo::ApiError (Unauthorized) on deliver_now.
      begin
        UserMailer.welcome_trial(@user).deliver_later
      rescue StandardError => e
        Rails.logger.error("[signup] welcome email enqueue failed for user #{@user.id}: #{e.class}: #{e.message}")
      end

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

  def set_marketing_nav
    @marketing_nav = true
  end
end
