# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolarController, type: :controller do
  let(:user) { create(:user, email_address: "test@example.com") }
  let(:polar_checkout_url) { "https://buy.polar.sh/polar_c_xxx" }

  before do
    session[:user_id] = user.id
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("POLAR_PRODUCT_ID").and_return("prod_123")
  end

  describe "POST #create_checkout" do
    it "requires authentication" do
      session[:user_id] = nil
      post :create_checkout
      expect(response).to redirect_to(login_path)
    end

    context "when user already purchased" do
      before do
        allow(user).to receive(:device_downloaded?).and_return(true)
        allow(user).to receive(:download_token).and_return(nil)
        allow(user).to receive(:generate_download_token!).and_return("token_123")
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "redirects to download page" do
        post :create_checkout
        expect(response).to redirect_to(download_app_path(token: "token_123"))
      end
    end

    context "with successful Polar checkout" do
      before do
        allow(controller).to receive(:current_user).and_return(user)
        manager = instance_double(Polar::ProductManager)
        allow(Polar::ProductManager).to receive(:new).and_return(manager)
        allow(manager).to receive(:create_checkout).and_return(polar_checkout_url)
      end

      it "redirects to Polar checkout URL" do
        post :create_checkout
        expect(response).to redirect_to(polar_checkout_url)
      end
    end

    context "when POLAR_PRODUCT_ID is missing" do
      before do
        allow(ENV).to receive(:[]).with("POLAR_PRODUCT_ID").and_return(nil)
        allow(Rails.application.credentials).to receive(:dig).with(:polar, :product_id).and_return(nil)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "redirects to settings with error" do
        post :create_checkout
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to include("not configured")
      end
    end
  end

  describe "GET #success" do
    it "requires authentication" do
      session[:user_id] = nil
      get :success
      expect(response).to redirect_to(login_path)
    end

    context "when user already purchased" do
      before do
        allow(user).to receive(:device_downloaded?).and_return(true)
        allow(user).to receive(:download_token).and_return(nil)
        allow(user).to receive(:generate_download_token!).and_return("token_123")
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "redirects to download" do
        get :success
        expect(response).to redirect_to(download_app_path(token: "token_123"))
      end
    end

    context "when user has not purchased yet" do
      before do
        allow(user).to receive(:device_downloaded?).and_return(false)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "redirects to settings with wait message" do
        get :success
        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to include("Thank you")
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
end
