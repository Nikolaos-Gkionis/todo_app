class RegistrationsController < ApplicationController
  # Allow access to signup pages without authentication
  skip_before_action :require_login, only: [ :new, :create ]
  skip_before_action :check_trial_status, only: [ :new, :create ]
  skip_before_action :block_expired_hosted_week!, only: [ :new, :create ]
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

      # On peponi.to this starts the 7-day hosted week. Self-host does nothing here.
      @user.start_trial!

      begin
        UserMailer.welcome_trial(@user).deliver_later
      rescue StandardError => e
        Rails.logger.error("[signup] welcome email enqueue failed for user #{@user.id}: #{e.class}: #{e.message}")
      end

      notice = if @user.hosted_ephemeral?
        "Account created. You have a week on this server. Clone the repo if you want to keep it."
      else
        "Account created. This instance is yours."
      end

      redirect_to app_root_path, notice: notice
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
