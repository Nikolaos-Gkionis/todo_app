require "rails_helper"

RSpec.describe DownloadsController, type: :controller do
  let(:user) { create(:user, :with_trial) }

  before do
    session[:user_id] = user.id
    allow(DataExportService).to receive(:export_user_data).and_return('{"pages": []}')
  end

  describe "GET #show" do
    it "renders the download page" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #download" do
    it "sends JSON export" do
      get :download
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")
    end
  end
end
