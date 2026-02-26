class StripeController < ApplicationController
  before_action :require_login
  before_action :configure_stripe

  def create_checkout_session
    # Existing customers: send them to download page, not checkout
    if current_user.device_downloaded?
      download_token = current_user.download_token || current_user.generate_download_token!
      redirect_to download_app_path(token: download_token),
                  notice: "You already own Todo-it! Your download is ready."
      return
    end

    # Create a Stripe checkout session for premium upgrade
    begin
      session = Stripe::Checkout::Session.create({
        customer_email: current_user.email_address,
        payment_method_types: [ "card" ],
        line_items: [ {
          price_data: {
            currency: "usd",
            product_data: {
              name: "Todo-it - Download to Device",
              description: "Download to your device forever - unlimited pages, offline access, and data ownership"
            },
            unit_amount: 990 # $9.99 in cents
          },
          quantity: 1
        } ],
        mode: "payment",
        success_url: success_stripe_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_stripe_url,
        metadata: {
          user_id: current_user.id
        }
      })

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe checkout creation failed: #{e.class} - #{e.message}"
      alert_msg = "Payment setup failed. Please try again or contact support if the issue persists."
      alert_msg += " (Dev: #{e.class})" if Rails.env.development?
      redirect_to settings_path, alert: alert_msg
    end
  end

  def success
    # Handle successful payment (idempotent: safe to refresh)
    session_id = params[:session_id]

    if session_id.blank?
      redirect_to pricing_path, alert: "Invalid payment session."
      return
    end

    begin
      session = Stripe::Checkout::Session.retrieve(session_id)

      # Verify this session belongs to the current user (prevents session hijacking)
      # Newer sessions have metadata.user_id; older sessions (pre-metadata) use email match
      # Note: Stripe returns StripeObject (not Hash), so use [] not dig
      meta = session.metadata
      session_user_id = (meta && meta["user_id"])&.to_s
      session_email = session.customer_details&.email || session.customer_email
      belongs_to_user = session_user_id == current_user.id.to_s
      belongs_to_user ||= session_email.present? && session_email.downcase == current_user.email_address.downcase

      unless belongs_to_user
        Rails.logger.warn "Stripe success: session user_id=#{session_user_id} email=#{session_email} vs current user #{current_user.id} #{current_user.email_address}"
        redirect_to pricing_path, alert: "This payment session doesn't belong to your account."
        return
      end

      if session.payment_status != "paid"
        redirect_to pricing_path, alert: "Payment was not completed successfully."
        return
      end

      # If user already purchased (e.g. page refresh), skip processing and redirect to download
      if current_user.device_downloaded?
        download_token = current_user.download_token || current_user.generate_download_token!
        redirect_to download_app_path(token: download_token),
                    notice: "Your app is ready to download. 🎉"
        return
      end

      # First-time processing: mark purchased, generate token, send email
      current_user.mark_as_downloaded!
      download_token = current_user.generate_download_token!

      AnalyticsService.track_trial_conversion(current_user)
      AnalyticsService.track_payment_completion(current_user, session.id)

      download_url = download_app_url(token: download_token)
      UserMailer.purchase_confirmation(current_user, download_url).deliver_now

      redirect_to download_app_path(token: download_token),
                  notice: "Payment successful! Your app is ready to download. 🎉"
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe success error: #{e.class} - #{e.message}"
      alert_msg = "Something went wrong processing your payment. Please contact support if the charge appears on your card."
      alert_msg += " (Dev: #{e.class} - check log)" if Rails.env.development?
      redirect_to pricing_path, alert: alert_msg
    end
  end

  def cancel
    # Handle cancelled payment
    redirect_to settings_path, alert: "Payment was cancelled. No charges were made."
  end

  def customer_portal
    # Create a customer portal session for managing billing
    # Note: This requires the user to have a Stripe customer ID stored
    # For now, redirect to the pricing page
    redirect_to pricing_path, notice: "Customer portal coming soon! For now, contact support to manage your billing."
  end

  def webhook
    # Handle Stripe webhooks for payment confirmation
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid payload: #{e.message}"
      render json: { error: "Invalid payload" }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid signature: #{e.message}"
      render json: { error: "Invalid signature" }, status: 400
      return
    end

    # Handle the event
    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event.data.object)
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    render json: { received: true }, status: 200
  end

  private

  def handle_checkout_session_completed(session)
    user_id = session.metadata["user_id"]
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    # Mark user as having downloaded app and generate download token
    user.mark_as_downloaded!
    download_token = user.generate_download_token!

    # Track conversion analytics
    AnalyticsService.track_trial_conversion(user)
    AnalyticsService.track_payment_completion(user, session.id)

    # Send purchase confirmation email
    download_url = download_app_url(token: download_token)
    UserMailer.purchase_confirmation(user, download_url).deliver_now

    Rails.logger.info "Payment completed for user #{user_id} via webhook"
  end

  def handle_payment_intent_succeeded(payment_intent)
    # Additional payment confirmation if needed
    Rails.logger.info "Payment intent succeeded: #{payment_intent.id}"
  end

  def configure_stripe
    key = ENV["STRIPE_SECRET_KEY"]
    if key.blank?
      Rails.logger.error "STRIPE_SECRET_KEY is not set"
      redirect_to settings_path, alert: "Payment is not configured. Please set STRIPE_SECRET_KEY."
      return
    end
    Stripe.api_key = key
  end
end
