# frozen_string_literal: true

# Handles post-purchase flow: waiting for webhook, then guiding users to download + PWA install
class PurchaseController < ApplicationController
  before_action :require_login

  # Landing page after Polar success. Polls until webhook has processed, then redirects to download page.
  def complete
    # If webhook already processed, send them straight to download page (with full instructions)
    if current_user.device_downloaded?
      redirect_to download_path,
                  notice: "Payment successful! Your app is ready to download. 🎉"
      return
    end

    # Show "setting up" page - the view will poll /app/purchase/status
    render :complete
  end

  # JSON endpoint for polling: has the webhook fulfilled this user yet?
  def status
    if current_user.device_downloaded?
      # Redirect to download page (has instructions + Download App button), not direct file download
      render json: { ready: true, download_url: download_url }
    else
      render json: { ready: false }
    end
  end
end
