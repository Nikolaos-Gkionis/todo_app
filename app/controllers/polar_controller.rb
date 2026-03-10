# frozen_string_literal: true

class PolarController < ApplicationController
  before_action :require_login
  skip_before_action :verify_authenticity_token, only: [] # webhook is in separate controller

  def create_checkout
    # Existing customers: send them to download page, not checkout
    if current_user.device_downloaded?
      download_token = current_user.download_token || current_user.generate_download_token!
      redirect_to download_app_path(token: download_token),
                  notice: "You already own Todo-it! Your download is ready."
      return
    end

    product_id = ENV["POLAR_PRODUCT_ID"] || Rails.application.credentials.dig(:polar, :product_id)
    if product_id.blank?
      Rails.logger.error "POLAR_PRODUCT_ID is not set"
      redirect_to app_root_path, alert: "Payment is not configured. Please contact support."
      return
    end

    # Optional: 100% test discount for local/dev (set POLAR_TEST_DISCOUNT_ID)
    discount_id = ENV["POLAR_TEST_DISCOUNT_ID"].presence

    manager = Polar::ProductManager.new
    checkout_url = manager.create_checkout(
      product_id: product_id,
      customer_email: current_user.email_address,
      success_url: success_polar_url,
      return_url: cancel_polar_url,
      discount_id: discount_id,
      metadata: { user_id: current_user.id.to_s }
    )
    redirect_to checkout_url, allow_other_host: true
  rescue Polar::ProductManager::Error => e
    Rails.logger.error "Polar checkout failed: #{e.message}"
    alert_msg = "Payment setup failed. Please try again or contact support if the issue persists."
    alert_msg += " (Dev: #{e.class})" if Rails.env.development?
    redirect_to app_root_path, alert: alert_msg
  end

  def success
    # Polar redirects here after payment. The actual fulfillment happens via webhook (order.paid).
    # If user arrives here before webhook processes, redirect to download if they're already marked.
    if current_user.device_downloaded?
      download_token = current_user.download_token || current_user.generate_download_token!
      redirect_to download_app_path(token: download_token),
                  notice: "Payment successful! Your app is ready to download. 🎉"
      return
    end

    # Webhook may not have processed yet - show a short wait message and suggest refresh
    redirect_to app_root_path,
                notice: "Thank you for your purchase! We're setting up your download. Please refresh in a moment, or check your email for the download link."
  end

  def cancel
    redirect_to app_root_path, alert: "Payment was cancelled. No charges were made."
  end
end
