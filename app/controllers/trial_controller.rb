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
    Rails.logger.info "Export data requested for user #{@user.id}"

    if @user.trial_active? || @user.device_downloaded?
      begin
        Rails.logger.info "User has active trial or downloaded app, proceeding with export"
        json_data = DataExportService.export_user_data(@user)
        Rails.logger.info "Data export successful, JSON size: #{json_data.length} bytes"

        # Mark data as exported (but don't mark as downloaded yet)
        @user.update!(trial_data_exported: true)

        # Send the JSON file as a download
        send_data json_data,
                  filename: "todo-it-data-#{@user.id}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.json",
                  type: "application/json",
                  disposition: "attachment"
      rescue => e
        Rails.logger.error "Data export failed for user #{@user.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        flash[:error] = "Data export failed. Please try again or contact support."
        redirect_to app_root_path
      end
    else
      Rails.logger.info "User does not have active trial or downloaded app"
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
