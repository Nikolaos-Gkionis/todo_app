# frozen_string_literal: true

require "rails_helper"

RSpec.describe Legacy::StripeController, type: :controller do
  let(:user) { create(:user, email_address: "test@example.com") }
  let(:stripe_session_id) { "cs_test_123456789" }
  let(:stripe_session_url) { "https://checkout.stripe.com/pay/cs_test_123456789" }

  before do
    session[:user_id] = user.id
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("STRIPE_SECRET_KEY").and_return("sk_test_123456789")
    allow(ENV).to receive(:[]).with("STRIPE_WEBHOOK_SECRET").and_return("whsec_123456789")
  end

  describe "POST #create_checkout_session" do
    it "requires authentication" do
      session[:user_id] = nil
      post :create_checkout_session
      expect(response).to redirect_to(login_path)
    end

    context "with successful Stripe session creation" do
      let(:mock_session) { double("Stripe::Checkout::Session", url: stripe_session_url) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(Stripe::Checkout::Session).to receive(:create).and_return(mock_session)
      end

      it "redirects to Stripe checkout URL" do
        post :create_checkout_session
        expect(response).to redirect_to(stripe_session_url)
      end
    end

    context "with Stripe API error" do
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_raise(
          Stripe::StripeError.new("Card declined")
        )
      end

      it "redirects to settings with error message" do
        post :create_checkout_session
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to include("Polar")
      end
    end
  end

  describe "GET #cancel" do
    it "redirects to settings with cancellation message" do
      get :cancel
      expect(response).to redirect_to(settings_path)
      expect(flash[:alert]).to eq("Payment was cancelled. No charges were made.")
    end
  end

  describe "POST #webhook" do
    it "handles webhook requests" do
      post :webhook
      expect(response).to have_http_status(:success).or have_http_status(:bad_request)
    end
  end
end
