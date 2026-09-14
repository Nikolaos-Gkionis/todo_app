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

  describe "POST /api/v1/days/:date/tasks" do
    let(:day) { Date.current }

    it "creates a dated Focus task for a paid user" do
      token = login_as(paid_user)
      expect {
        post "/api/v1/days/#{day.iso8601}/tasks",
          params: { title: "Buy milk" },
          headers: auth_headers(token),
          as: :json
      }.to change { paid_user.todos.count }.by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("task", "title")).to eq("Buy milk")
      expect(body.dig("task", "id")).to be_present
      expect(body.dig("task", "completed")).to eq(false)

      todo = paid_user.todos.find(body.dig("task", "id"))
      expect(todo.due_date).to eq(day)
      expect(todo.page_id).to be_nil
    end

    it "returns 422 for a blank title" do
      token = login_as(paid_user)
      post "/api/v1/days/#{day.iso8601}/tasks",
        params: { title: "  " },
        headers: auth_headers(token),
        as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("validation_failed")
    end

    it "returns 401 without a token" do
      post "/api/v1/days/#{day.iso8601}/tasks",
        params: { title: "Nope" },
        headers: { "ACCEPT" => "application/json" },
        as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/todos/:id" do
    it "deletes a todo the paid user owns" do
      token = login_as(paid_user)
      todo = create(:todo, user: paid_user, page: nil, due_date: Date.current, title: "Drop me")

      expect {
        delete "/api/v1/todos/#{todo.id}", headers: auth_headers(token)
      }.to change { paid_user.todos.count }.by(-1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
      expect(body["id"]).to eq(todo.id)
    end

    it "returns 404 for another user's todo" do
      token = login_as(paid_user)
      other = create(:user, password: password, password_confirmation: password, paid_at: Time.current)
      foreign = create(:todo, user: other, page: nil, due_date: Date.current, title: "Not yours")

      delete "/api/v1/todos/#{foreign.id}", headers: auth_headers(token)
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("not_found")
      expect(Todo.find_by(id: foreign.id)).to be_present
    end

    it "returns 401 without a token" do
      todo = create(:todo, user: paid_user, page: nil, due_date: Date.current, title: "Keep")
      delete "/api/v1/todos/#{todo.id}", headers: { "ACCEPT" => "application/json" }
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

  describe "GET /api/v1/export" do
    let(:day) { Date.current }

    before do
      create(:todo, user: paid_user, page: nil, due_date: day, title: "Ship API", completed: false, position: 1)
      page = create(:page, user: paid_user, name: "Someday")
      create(:todo, user: paid_user, page: page, due_date: nil, title: "Book dentist", position: 1)
    end

    it "returns a snapshot of dated Focus tasks and Not Yet items" do
      token = login_as(paid_user)
      get "/api/v1/export", headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["days"][day.iso8601].first["title"]).to eq("Ship API")
      expect(body["not_yet"].first["title"]).to eq("Book dentist")
      expect(body["not_yet"].first["list"]).to eq("Someday")
      expect(body.dig("user", "email")).to eq(paid_user.email_address)
    end

    it "returns 401 without a token" do
      get "/api/v1/export", headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/not_yet/tasks" do
    it "creates an undated list todo on an existing page" do
      page = create(:page, user: paid_user, name: "Inbox")
      token = login_as(paid_user)

      expect {
        post "/api/v1/not_yet/tasks",
          params: { title: "Call mum" },
          headers: auth_headers(token),
          as: :json
      }.to change { paid_user.todos.count }.by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("task", "title")).to eq("Call mum")
      todo = paid_user.todos.find(body.dig("task", "id"))
      expect(todo.page_id).to eq(page.id)
      expect(todo.due_date).to be_nil
    end

    it "creates a default page when the user has none" do
      token = login_as(paid_user)
      expect(paid_user.pages).to be_empty

      post "/api/v1/not_yet/tasks",
        params: { title: "First inbox item" },
        headers: auth_headers(token),
        as: :json

      expect(response).to have_http_status(:created)
      expect(paid_user.pages.reload.first.name).to eq("Not Yet")
      expect(paid_user.todos.last.page_id).to eq(paid_user.pages.first.id)
    end

    it "returns 422 for a blank title" do
      token = login_as(paid_user)
      post "/api/v1/not_yet/tasks",
        params: { title: "  " },
        headers: auth_headers(token),
        as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
