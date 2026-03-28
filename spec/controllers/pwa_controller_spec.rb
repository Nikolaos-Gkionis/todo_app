# frozen_string_literal: true

require "rails_helper"

RSpec.describe PwaController, type: :controller do
  let(:trial_user) { create(:user, :with_trial, device_downloaded: false, paid_at: nil) }
  let(:paid_user) { create(:user, device_downloaded: false, paid_at: Time.current) }
  let(:legacy_downloaded_user) { create(:user, :downloaded_app, paid_at: nil) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:check_trial_status)
  end

  describe "GET #manifest" do
    it "returns unauthorized when not logged in" do
      get :manifest, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for a trial user who has not purchased" do
      session[:user_id] = trial_user.id
      get :manifest, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns JSON for a user with paid_at" do
      session[:user_id] = paid_user.id
      get :manifest, format: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["name"]).to include("Peponi")
      expect(json["icons"].first["src"]).to include("peponito")
    end

    it "returns JSON for a legacy user with device_downloaded" do
      session[:user_id] = legacy_downloaded_user.id
      get :manifest, format: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #service_worker" do
    it "returns unauthorized when not logged in" do
      get :service_worker, format: :js
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for a trial user who has not purchased" do
      session[:user_id] = trial_user.id
      get :service_worker, format: :js
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns JavaScript for a paid user" do
      session[:user_id] = paid_user.id
      get :service_worker, format: :js
      expect(response).to have_http_status(:success)
      expect(response.body).to include("CACHE_NAME")
      expect(response.body).to include("peponito")
    end
  end
end
