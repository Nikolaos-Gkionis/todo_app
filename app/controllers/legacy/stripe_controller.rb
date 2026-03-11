# frozen_string_literal: true

# Legacy Stripe controller - kept for historical data reference.
# Payments have been migrated to Polar.sh (Merchant of Record).
# See PolarController and Webhooks::PolarController for current implementation.
module Legacy
  class StripeController < ApplicationController
    before_action :require_login
    before_action :configure_stripe

    def create_checkout_session
      if current_user.device_downloaded?
        download_token = current_user.download_token || current_user.generate_download_token!
        redirect_to download_app_path(token: download_token),
                    notice: "You already own Task Days! Your download is ready."
        return
      end

      begin
        session = Stripe::Checkout::Session.create({
          customer_email: current_user.email_address,
          payment_method_types: [ "card" ],
          line_items: [ {
            price_data: {
              currency: "usd",
              product_data: {
                name: "Task Days - Download to Device",
                description: "Download to your device forever - unlimited pages, offline access, and data ownership"
              },
              unit_amount: 990
            },
            quantity: 1
          } ],
          mode: "payment",
          success_url: success_stripe_url + "?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: cancel_stripe_url,
          metadata: { user_id: current_user.id }
        })
        redirect_to session.url, allow_other_host: true
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe checkout creation failed: #{e.class} - #{e.message}"
        redirect_to settings_path, alert: "Payment has moved to Polar. Please use the Buy button."
      end
    end

    def success
      session_id = params[:session_id]
      redirect_to pricing_path, alert: "Invalid payment session." and return if session_id.blank?

      begin
        session = Stripe::Checkout::Session.retrieve(session_id)
        meta = session.metadata
        session_user_id = (meta && meta["user_id"])&.to_s
        session_email = session.customer_details&.email || session.customer_email
        belongs_to_user = session_user_id == current_user.id.to_s
        belongs_to_user ||= session_email.present? && session_email.downcase == current_user.email_address.downcase
        unless belongs_to_user
          redirect_to pricing_path, alert: "This payment session doesn't belong to your account."
          return
        end
        if session.payment_status != "paid"
          redirect_to pricing_path, alert: "Payment was not completed successfully."
          return
        end
        if current_user.device_downloaded?
          download_token = current_user.download_token || current_user.generate_download_token!
          redirect_to download_app_path(token: download_token), notice: "Your app is ready to download. 🎉"
          return
        end
        current_user.mark_as_downloaded!
        download_token = current_user.generate_download_token!
        AnalyticsService.track_trial_conversion(current_user)
        AnalyticsService.track_payment_completion(current_user, session.id)
        UserMailer.purchase_confirmation(current_user, download_app_url(token: download_token)).deliver_now
        redirect_to download_app_path(token: download_token),
                    notice: "Payment successful! Your app is ready to download. 🎉"
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe success error: #{e.class} - #{e.message}"
        redirect_to pricing_path, alert: "Something went wrong. Please contact support if the charge appears on your card."
      end
    end

    def cancel
      redirect_to settings_path, alert: "Payment was cancelled. No charges were made."
    end

    def customer_portal
      redirect_to pricing_path, notice: "Customer portal coming soon! For now, contact support."
    end

    def webhook
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]
      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError, Stripe::SignatureVerificationError
        render json: { error: "Invalid payload or signature" }, status: 400
        return
      end
      case event.type
      when "checkout.session.completed"
        handle_checkout_session_completed(event.data.object)
      when "payment_intent.succeeded"
        Rails.logger.info "Payment intent succeeded: #{event.data.object.id}"
      end
      render json: { received: true }, status: 200
    end

    private

    def handle_checkout_session_completed(session)
      user = User.find_by(id: session.metadata["user_id"])
      return unless user
      user.mark_as_downloaded!
      download_token = user.generate_download_token!
      AnalyticsService.track_trial_conversion(user)
      AnalyticsService.track_payment_completion(user, session.id)
      UserMailer.purchase_confirmation(user, download_app_url(token: download_token)).deliver_now
      Rails.logger.info "Legacy Stripe: Payment completed for user #{user.id}"
    end

    def configure_stripe
      key = ENV["STRIPE_SECRET_KEY"]
      if key.blank?
        redirect_to settings_path, alert: "Legacy Stripe not configured. Payments use Polar."
        return
      end
      Stripe.api_key = key
    end
  end
end
