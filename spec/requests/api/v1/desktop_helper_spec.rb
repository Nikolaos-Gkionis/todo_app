# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 desktop helper", type: :request do
  let(:password) { "password123" }
  let(:paid_user) { create(:user, password: password, password_confirmation: password, paid_at: Time.current, device_downloaded: false) }
  let(:legacy_user) { create(:user, :downloaded_app, password: password, password_confirmation: password, paid_at: nil) }
  let(:trial_user) { create(:user, :with_trial, password: password, password_confirmation: password, device_downloaded: false, paid_at: nil) }

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}", "ACCEPT" => "application/json" }
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email_address, password: password }, as: :json
    expect(response).to have_http_status(:ok)
    JSON.parse(response.body).fetch("token")
  end

  describe "POST /api/v1/auth/login" do
    it "returns a token for a paid user" do
      post "/api/v1/auth/login", params: { email: paid_user.email_address, password: password }, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["email"]).to eq(paid_user.email_address)
      expect(paid_user.reload.desktop_api_token_digest).to be_present
    end

    it "returns a token for a legacy downloaded user" do
      post "/api/v1/auth/login", params: { email_address: legacy_user.email_address, password: password }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 for bad password" do
      post "/api/v1/auth/login", params: { email: paid_user.email_address, password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("invalid_credentials")
    end

    it "returns 403 for a trial-only user" do
      post "/api/v1/auth/login", params: { email: trial_user.email_address, password: password }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]).to eq("paid_required")
    end
  end

  describe "GET /api/v1/auth/status" do
    it "returns authenticated status with a valid token" do
      token = login_as(paid_user)
      get "/api/v1/auth/status", headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["authenticated"]).to eq(true)
      expect(body["paid"]).to eq(true)
    end

    it "returns 401 without a token" do
      get "/api/v1/auth/status", headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "revokes the token" do
      token = login_as(paid_user)
      delete "/api/v1/auth/logout", headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
      get "/api/v1/auth/status", headers: auth_headers(token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/days/:date" do
    let(:day) { Date.current }

    before do
      create(:todo, user: paid_user, page: nil, due_date: day, title: "Ship API", completed: false, position: 1)
      create(:todo, user: paid_user, page: nil, due_date: day, title: "Done already", completed: true, position: 2)
      other_page = create(:page, user: paid_user, name: "Inbox")
      create(:todo, user: paid_user, page: other_page, due_date: nil, title: "List item", position: 1)
    end

    it "returns dated todos for the paid user" do
      token = login_as(paid_user)
      get "/api/v1/days/#{day.iso8601}", headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["date"]).to eq(day.iso8601)
      titles = body["tasks"].map { |t| t["title"] }
      expect(titles).to eq([ "Ship API", "Done already" ])
      expect(body["tasks"].first["completed"]).to eq(false)
    end

    it "returns 401 without auth" do
      get "/api/v1/days/#{day.iso8601}", headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/not_yet" do
    before do
      page = create(:page, user: paid_user, name: "Someday")
      create(:todo, user: paid_user, page: page, due_date: nil, title: "Book dentist", position: 1)
    end

    it "returns pages and list todos" do
      token = login_as(paid_user)
      get "/api/v1/not_yet", headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["title"]).to be_present
      expect(body["pages"].first["name"]).to eq("Someday")
      expect(body["pages"].first["todos"].first["title"]).to eq("Book dentist")
    end
  end
end
