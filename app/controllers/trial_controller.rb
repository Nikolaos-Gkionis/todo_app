class TrialController < ApplicationController
  before_action :require_login
  before_action :set_user

  # Show trial status and management
  def status
    # This will be used for trial status page
  end

  # Start a new trial for the user
  def start
    if @user.start_trial!
      flash[:success] = "Your 30-day free trial has started! Enjoy full access to all features."
      redirect_to app_root_path
    else
      flash[:error] = "Unable to start trial. You may already have an active trial or downloaded app."
      redirect_to app_root_path
    end
  end

  # Extend trial (for special cases)
  def extend
    if @user.trial_active?
      # Extend trial by 7 days (for special cases)
      @user.update!(trial_expires_at: @user.trial_expires_at + 7.days)
      flash[:success] = "Your trial has been extended by 7 days."
    else
      flash[:error] = "No active trial to extend."
    end
    redirect_to app_root_path
  end

  # Export trial data for download
  def export_data
    if @user.trial_active? || @user.device_downloaded?
      # This will be implemented when we create the DataExportService
      flash[:info] = "Data export feature coming soon!"
      redirect_to app_root_path
    else
      flash[:error] = "No data available to export."
      redirect_to app_root_path
    end
  end

  # Show download page
  def download
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to access this page."
      redirect_to app_root_path
      return
    end

    # Generate download token if not exists
    @download_token = @user.download_token || @user.generate_download_token!
  end

  private

  def set_user
    @user = current_user
  end
end
