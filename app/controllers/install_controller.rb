# frozen_string_literal: true

# PWA install guide. On peponi.to this is a shortcut to my server for the hosted week.
# On your own instance it is a real local install.
class InstallController < ApplicationController
  skip_before_action :require_login, if: :token_provided?
  before_action :set_user
  before_action :authenticate_user_or_token!

  def show
    unless @user.can_use_app?
      flash[:info] = flash_hosted_week_ended
      redirect_to root_path
      return
    end
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
