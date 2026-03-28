# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstallController, type: :controller do
  let(:downloaded_user) { create(:user, :downloaded_app, download_token: "install_token_123") }
  let(:trial_user) { create(:user, :with_trial, download_token: "trial_token_456") }
  let(:expired_user) { create(:user, :trial_expired, download_token: nil) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:check_trial_status)
  end

  describe "GET #show" do
    it "requires authentication when no token provided" do
      session[:user_id] = nil
      get :show
      expect(response).to redirect_to(login_path)
    end

    context "when logged in with downloaded user" do
      before { session[:user_id] = downloaded_user.id }

      it "renders the install template" do
        get :show
        expect(response).to render_template(:show)
        expect(response).to have_http_status(:success)
      end

      it "assigns download token" do
        get :show
        expect(assigns(:download_token)).to eq("install_token_123")
      end
    end

    context "when accessed via valid token" do
      it "renders the install template without login" do
        downloaded_user # ensure user with token exists
        get :show, params: { token: "install_token_123" }
        expect(response).to render_template(:show)
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid token" do
      it "redirects to login" do
        get :show, params: { token: "invalid_token" }
        expect(response).to redirect_to(login_path)
        expect(flash[:error]).to include("Invalid or expired")
      end
    end

    context "with expired trial user" do
      before { session[:user_id] = expired_user.id }

      it "redirects to pricing (no app access after trial)" do
        get :show
        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include("free trial has ended")
      end
    end
  end
end
