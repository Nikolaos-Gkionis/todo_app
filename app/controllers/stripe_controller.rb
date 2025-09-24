class StripeController < ApplicationController
  before_action :require_login
  before_action :configure_stripe

  def create_checkout_session
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
      redirect_to settings_path, alert: "Payment setup failed: #{e.message}"
    end
  end

  def success
    # Handle successful payment
    session_id = params[:session_id]

    if session_id
      begin
        session = Stripe::Checkout::Session.retrieve(session_id)

        if session.payment_status == "paid"
          # Mark user as having downloaded app and generate download token
          current_user.mark_as_downloaded!
          download_token = current_user.generate_download_token!

          redirect_to download_app_path(token: download_token),
                      notice: "Payment successful! Your app is ready to download. 🎉"
        else
          redirect_to pricing_path, alert: "Payment was not completed successfully."
        end
      rescue Stripe::StripeError => e
        redirect_to pricing_path, alert: "Error processing payment: #{e.message}"
      end
    else
      redirect_to pricing_path, alert: "Invalid payment session."
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

  private

  def configure_stripe
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  end
end
