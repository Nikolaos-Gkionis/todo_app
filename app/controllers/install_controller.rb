# frozen_string_literal: true

# Post-payment PWA install guide. Stays within app flow — no marketing mix.
# Accessible when logged in or via token (from email).
class InstallController < ApplicationController
  skip_before_action :require_login, if: :token_provided?
  before_action :set_user
  before_action :authenticate_user_or_token!

  def show
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to view this guide."
      redirect_to app_root_path
      return
    end

    # Token for linking back to download (when accessed via email)
    @download_token = @user.download_token || @user.generate_download_token!
  end

  private

  def token_provided?
    params[:token].present?
  end

  def authenticate_user_or_token!
    return if @user.present?

    if params[:token].present?
      flash[:error] = "Invalid or expired link. Please sign in or open the download page from your email."
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
