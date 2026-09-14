# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Trial user access", type: :request do
  let(:password) { "password123" }
  let(:trial_user) do
    create(
      :user,
      :with_trial,
      password: password,
      password_confirmation: password,
      device_downloaded: false,
      paid_at: nil
    )
  end

  def login_html_session(user)
    post "/login", params: {
      email_address: user.email_address,
      password: password
    }
    follow_redirect! while response.redirect?
  end

  describe "website trial (before paying)" do
    it "loads the dashboard without a 500" do
      login_html_session(trial_user)
      get "/app"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dashboard")
    end

    it "does not expose PWA install hooks in the HTML" do
      login_html_session(trial_user)
      get "/app"
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('rel="manifest"')
      expect(response.body).not_to include("service-worker.js")
      expect(response.body).not_to include("apple-mobile-web-app-capable")
      expect(response.body).not_to include("Install App")
    end

    it "rejects the PWA manifest and service worker" do
      login_html_session(trial_user)
      get "/manifest.json"
      expect(response).to have_http_status(:unauthorized)
      get "/service-worker.js"
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not serve the download page or ZIP" do
      trial_user.update!(download_token: "trial-token")
      login_html_session(trial_user)
      get download_path
      expect(response).to redirect_to(pricing_path)
      get download_app_path, params: { token: "trial-token" }
      expect(response).to redirect_to(pricing_path)
    end

    it "does not serve the PWA install guide" do
      login_html_session(trial_user)
      get install_pwa_path
      expect(response).to redirect_to(pricing_path)
    end
  end

  describe "new trial signup" do
    it "creates the account, starts the trial, and loads /app" do
      post "/signup", params: {
        user: {
          name: "Trial Person",
          email_address: "signup-trial@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
      expect(response).to redirect_to(app_root_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)

      user = User.find_by(email_address: "signup-trial@example.com")
      expect(user).to be_present
      expect(user.trial_active?).to be true
      expect(user.can_install_pwa?).to be false
    end

    it "still creates the account if the welcome email fails" do
      mail = instance_double(ActionMailer::MessageDelivery)
      allow(UserMailer).to receive(:welcome_trial).and_return(mail)
      allow(mail).to receive(:deliver_later).and_raise(StandardError, "brevo unauthorized")

      expect {
        post "/signup", params: {
          user: {
            name: "Mail Fail",
            email_address: "mail-fail-trial@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(app_root_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Omarchy / desktop API" do
    it "rejects trial credentials with 403, not 500" do
      post "/api/v1/auth/login",
        params: { email: trial_user.email_address, password: password },
        as: :json
      expect(response).to have_http_status(:forbidden)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("paid_required")
      expect(body["message"]).to match(/local/i)
    end
  end
end
