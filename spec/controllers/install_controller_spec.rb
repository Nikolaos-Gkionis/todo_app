require "rails_helper"

RSpec.describe InstallController, type: :controller do
  let(:user) { create(:user, :with_trial) }

  before { session[:user_id] = user.id }

  describe "GET #show" do
    it "renders the install guide" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end
end
