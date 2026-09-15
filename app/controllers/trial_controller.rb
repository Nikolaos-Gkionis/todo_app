class TrialController < ApplicationController
  before_action :require_login
  before_action :set_user

  def status
  end

  def export_data
    unless @user.can_use_app? || (@user.hosted_ephemeral? && @user.trial_expired?)
      flash[:error] = "No data available to export."
      redirect_to app_root_path
      return
    end

    begin
      json_data = DataExportService.export_user_data(@user)
      @user.update!(trial_data_exported: true)

      send_data json_data,
                filename: "peponito-data-#{@user.id}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.json",
                type: "application/json",
                disposition: "attachment"
    rescue => e
      Rails.logger.error "Data export failed for user #{@user.id}: #{e.message}"
      flash[:error] = "Data export failed. Please try again."
      redirect_to app_root_path
    end
  end

  private

  def set_user
    @user = current_user
  end
end
