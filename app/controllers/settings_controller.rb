class SettingsController < ApplicationController
  before_action :require_login

  def index
    @user = current_user
  end

  def update
    @user = current_user

    return redirect_to settings_path, alert: "Invalid request." unless params[:user].present?

    # Handle password update separately
    if params[:user][:password].present?
      if @user.authenticate(params[:user][:current_password])
        if @user.update(user_params.except(:current_password))
          # Send password change notification email
          UserMailer.password_changed(@user).deliver_now
          redirect_to settings_path, notice: "Account updated successfully!"
        else
          render :index, status: :unprocessable_entity
        end
      else
        @user.errors.add(:current_password, "is incorrect")
        render :index, status: :unprocessable_entity
      end
    else
      # Check if sensitive fields (email) are being updated (only when email param is present)
      sensitive_changes = params[:user][:email_address].present? && params[:user][:email_address] != @user.email_address

      if sensitive_changes
        # Require current password for sensitive changes
        if @user.authenticate(params[:user][:current_password])
          # Store old email for notification
          old_email = @user.email_address
          if @user.update(user_params.except(:password, :password_confirmation, :current_password))
            # Send email change notification to old email address
            UserMailer.email_changed(@user, old_email).deliver_now
            redirect_to settings_path, notice: "Account updated successfully!"
          else
            render :index, status: :unprocessable_entity
          end
        else
          @user.errors.add(:current_password, "is incorrect")
          render :index, status: :unprocessable_entity
        end
      else
        # Update non-sensitive fields (name, accent_color, font_family) without password
        if @user.update(user_params.except(:password, :password_confirmation, :current_password))
          respond_to do |format|
            format.html do
              notice = appearance_only_update? ? "Appearance updated!" : "Account updated successfully!"
              redirect_to settings_path, notice: notice
            end
            format.json { render json: { status: "success" } }
          end
        else
          respond_to do |format|
            format.html { render :index, status: :unprocessable_entity }
            format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  def delete
    @user = current_user
  end

  def update_theme
    theme = params[:theme]

    if %w[classic lined graph vintage dark].include?(theme)
      session[:theme] = theme
      render json: { status: "success", theme: theme }
    else
      render json: { status: "error", message: "Invalid theme" }, status: 400
    end
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
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :current_password, :accent_color, :font_family, :app_title, :roll_over, :not_yet_panel_title, :lists_placement)
  end

  def appearance_only_update?
    p = params[:user] || {}
    p[:accent_color].present? || p[:font_family].present? || p[:app_title].present? || p[:not_yet_panel_title].present? || p.key?(:roll_over) || p[:lists_placement].present?
  end
end
