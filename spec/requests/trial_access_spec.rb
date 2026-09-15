# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hosted week access", type: :request do
  let(:password) { "password123" }
  let(:user) do
    create(
      :user,
      :with_trial,
      password: password,
      password_confirmation: password
    )
  end

  def login_html_session(account)
    post "/login", params: {
      email_address: account.email_address,
      password: password
    }
    follow_redirect! while response.redirect?
  end

  it "loads the dashboard" do
    login_html_session(user)
    get "/app"
    expect(response).to have_http_status(:ok)
  end

  it "exposes PWA install hooks" do
    login_html_session(user)
    get "/app"
    expect(response.body).to include('rel="manifest"')
  end

  it "serves the PWA manifest" do
    login_html_session(user)
    get "/manifest.json"
    expect(response).to have_http_status(:ok)
  end

  describe "expired hosted week" do
    let(:expired) do
      create(
        :user,
        :trial_expired,
        password: password,
        password_confirmation: password
      )
    end

    before { enable_hosted_ephemeral! }

    it "keeps the user off /app" do
      login_html_session(expired)
      get "/app"
      expect(response).to redirect_to(root_path)
    end
  end
end
