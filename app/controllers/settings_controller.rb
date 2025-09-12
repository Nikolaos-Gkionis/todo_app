class SettingsController < ApplicationController
  before_action :require_login

  def index
    @user = current_user
  end

  def update
    @user = current_user

    # Handle password update separately
    if params[:user][:password].present?
      if @user.authenticate(params[:user][:current_password])
        if @user.update(user_params.except(:current_password))
          redirect_to settings_path, notice: "Account updated successfully!"
        else
          render :index, status: :unprocessable_entity
        end
      else
        @user.errors.add(:current_password, "is incorrect")
        render :index, status: :unprocessable_entity
      end
    else
      # Update email without password change
      if @user.update(user_params.except(:password, :password_confirmation, :current_password))
        redirect_to settings_path, notice: "Account updated successfully!"
      else
        render :index, status: :unprocessable_entity
      end
    end
  end

  def delete
    @user = current_user
  end

  def destroy
    @user = current_user

    # Verify the user wants to delete by checking a confirmation parameter
    if params[:confirm_deletion] == "DELETE"
      # Log out the user first
      session[:user_id] = nil

      # Delete the user and all associated data (pages and todos will be deleted via dependent: :destroy)
      @user.destroy

      redirect_to root_path, notice: "Your account has been successfully deleted. We're sorry to see you go!"
    else
      redirect_to delete_account_path, alert: "Please confirm account deletion by typing 'DELETE'"
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :current_password)
  end
end
