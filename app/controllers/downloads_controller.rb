class DownloadsController < ApplicationController
  skip_before_action :require_login, if: :token_provided?
  before_action :set_user
  before_action :authenticate_user_or_token!

  def show
    unless @user.can_use_app?
      flash[:info] = flash_hosted_week_ended
      redirect_to root_path
      return
    end

    @download_token = @user.download_token || @user.generate_download_token!
  end

  def download
    unless @user.can_use_app?
      flash[:info] = flash_hosted_week_ended
      redirect_to root_path
      return
    end

    json_data = DataExportService.export_user_data(@user)
    @user.update!(trial_data_exported: true)

    send_data json_data,
              filename: "peponito-data-#{@user.id}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.json",
              type: "application/json",
              disposition: "attachment"
  end

  def generate_token
    token = @user.generate_download_token!
    redirect_to download_path(token: token)
  end

  def mark_downloaded
    @user.mark_as_downloaded!
    redirect_to install_pwa_path
  end

  private

  def token_provided?
    params[:token].present?
  end

  def authenticate_user_or_token!
    return if @user.present?

    if params[:token].present?
      flash[:error] = "Invalid or expired link. Please sign in."
    else
      flash_login_required
    end
    redirect_to login_path
  end

  def set_user
    @user = if logged_in?
      current_user
    elsif params[:token].present?
      User.find_by(download_token: params[:token])
    end
  end
end
