# frozen_string_literal: true

require "rails_helper"

RSpec.describe PwaController, type: :controller do
  let(:user) { create(:user, :with_trial) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:check_trial_status)
  end

  describe "GET #manifest" do
    it "returns unauthorized when not logged in" do
      get :manifest, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns JSON for a signed-in user" do
      session[:user_id] = user.id
      get :manifest, format: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["name"]).to include("Peponi")
    end
  end
end
