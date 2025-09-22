class DownloadsController < ApplicationController
  before_action :require_login
  before_action :set_user

  # Show download page with instructions
  def show
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to access this page."
      redirect_to app_root_path
      return
    end

    # Generate download token if not exists
    @download_token = @user.download_token || @user.generate_download_token!
  end

  # Download the app bundle
  def download
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to download."
      redirect_to app_root_path
      return
    end

    # Verify download token
    unless params[:token] == @user.download_token
      flash[:error] = "Invalid download token."
      redirect_to app_root_path
      return
    end

    # Generate app bundle (this will be implemented when we create the PWA system)
    # For now, just redirect to the app with a success message
    @user.mark_as_downloaded!

    flash[:success] = "App downloaded successfully! You can now use Todo-it offline on your device."
    redirect_to app_root_path
  end

  # Generate new download token
  def generate_token
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to generate a download token."
      redirect_to app_root_path
      return
    end

    @download_token = @user.generate_download_token!
    flash[:success] = "New download token generated."
    redirect_to download_path
  end

  # Mark app as downloaded (for testing purposes)
  def mark_downloaded
    unless @user.trial_active?
      flash[:error] = "You need an active trial to mark as downloaded."
      redirect_to app_root_path
      return
    end

    @user.mark_as_downloaded!
    flash[:success] = "App marked as downloaded! You now have full access to all features."
    redirect_to app_root_path
  end

  private

  def set_user
    @user = current_user
  end
end
