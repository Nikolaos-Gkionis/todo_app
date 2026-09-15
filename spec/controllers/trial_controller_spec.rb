require "rails_helper"

RSpec.describe TrialController, type: :controller do
  let(:user) { create(:user, :with_trial) }

  before do
    session[:user_id] = user.id
    allow(DataExportService).to receive(:export_user_data).and_return('{"pages": []}')
  end

  describe "GET #status" do
    it "renders the status template" do
      get :status
      expect(response).to render_template(:status)
    end
  end

  describe "GET #export_data" do
    it "sends a JSON file" do
      get :export_data
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")
    end
  end
end
