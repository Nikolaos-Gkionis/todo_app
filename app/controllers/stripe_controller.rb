class StripeController < ApplicationController
  before_action :require_login

  def create_checkout_session
    # Create a Stripe checkout session for premium subscription
    begin
      session = Stripe::Checkout::Session.create({
        customer_email: current_user.email_address,
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'Todo-it Premium',
              description: 'Unlock all themes, unlimited pages, and premium features',
            },
            unit_amount: 2900, # $29.00 in cents
          },
          quantity: 1,
        }],
        mode: 'payment',
        success_url: success_stripe_url + '?session_id={CHECKOUT_SESSION_ID}',
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

        if session.payment_status == 'paid'
          # Update user to premium
          current_user.update(premium: true)

          redirect_to settings_path, notice: "Welcome to Todo-it Premium! 🎉"
        else
          redirect_to settings_path, alert: "Payment was not completed successfully."
        end
      rescue Stripe::StripeError => e
        redirect_to settings_path, alert: "Error processing payment: #{e.message}"
      end
    else
      redirect_to settings_path, alert: "Invalid payment session."
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
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  end
end
