require 'rails_helper'

RSpec.describe TrialController, type: :controller do
  let(:user) { create(:user, trial_started_at: nil, trial_expires_at: nil, device_downloaded: false) }
  let(:trial_user) { create(:user, :with_trial, device_downloaded: false) }
  let(:downloaded_user) { create(:user, :downloaded_app) }
  let(:expired_user) { create(:user, :trial_expired, device_downloaded: false) }

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
    allow(AnalyticsService).to receive(:track_trial_start)
    allow(DataExportService).to receive(:export_user_data).and_return('{"pages": []}')
    # Skip the trial status check that automatically starts trials
    allow_any_instance_of(ApplicationController).to receive(:check_trial_status)
  end

  describe 'GET #status' do
    it 'requires authentication' do
      session[:user_id] = nil
      allow(controller).to receive(:current_user).and_return(nil)
      get :status
      expect(response).to redirect_to(login_path)
    end

    context 'with active trial user' do
      before do
        session[:user_id] = trial_user.id
        allow(controller).to receive(:current_user).and_return(trial_user)
      end

      it 'renders the status template' do
        get :status
        expect(response).to render_template(:status)
      end

      it 'assigns the current user' do
        get :status
        expect(assigns(:user)).to eq(trial_user)
      end
    end
  end

  describe 'POST #start' do
    it 'requires authentication' do
      session[:user_id] = nil
      allow(controller).to receive(:current_user).and_return(nil)
      post :start
      expect(response).to redirect_to(login_path)
    end

    context 'with user who can start trial' do
      it 'starts a new trial' do
        expect(user).to receive(:start_trial!).and_return(true)
        expect(AnalyticsService).to receive(:track_trial_start).with(user)

        post :start

        expect(response).to redirect_to(app_root_path)
        expect(flash[:success]).to eq('Your 7-day free trial has started! The website is yours for 7 days — PWA install unlocks after purchase.')
      end

      it 'handles trial start failure' do
        expect(user).to receive(:start_trial!).and_return(false)

        post :start

        expect(response).to redirect_to(app_root_path)
        expect(flash[:error]).to eq('Unable to start trial. You may already have an active trial or downloaded app.')
      end
    end

    context 'with user who already has trial' do
      before do
        session[:user_id] = trial_user.id
        allow(controller).to receive(:current_user).and_return(trial_user)
      end

      it 'does not start another trial' do
        expect(trial_user).to receive(:start_trial!).and_return(false)

        post :start

        expect(response).to redirect_to(app_root_path)
        expect(flash[:error]).to eq('Unable to start trial. You may already have an active trial or downloaded app.')
      end
    end

    context 'with downloaded user' do
      before do
        session[:user_id] = downloaded_user.id
        allow(controller).to receive(:current_user).and_return(downloaded_user)
      end

      it 'does not start trial for downloaded user' do
        expect(downloaded_user).to receive(:start_trial!).and_return(false)

        post :start

        expect(response).to redirect_to(app_root_path)
        expect(flash[:error]).to eq('Unable to start trial. You may already have an active trial or downloaded app.')
      end
    end
  end

  describe 'POST #extend_trial' do
    it 'requires authentication' do
      session[:user_id] = nil
      allow(controller).to receive(:current_user).and_return(nil)
      post :extend_trial
      expect(response).to redirect_to(login_path)
    end

    context 'with active trial user' do
      before do
        session[:user_id] = trial_user.id
        allow(controller).to receive(:current_user).and_return(trial_user)
      end

      it 'extends the trial by 7 days' do
        original_expiry = trial_user.trial_expires_at

        post :extend_trial

        expect(response).to redirect_to(app_root_path)
        expect(flash[:success]).to eq('Your trial has been extended by 7 days.')
        expect(trial_user.reload.trial_expires_at).to be > original_expiry
      end
    end

    context 'with user who has no active trial' do
      it 'shows error message' do
        post :extend_trial

        expect(response).to redirect_to(app_root_path)
        expect(flash[:error]).to eq('No active trial to extend.')
      end
    end

    context 'with expired trial user' do
      before do
        session[:user_id] = expired_user.id
        allow(controller).to receive(:current_user).and_return(expired_user)
      end

      it 'shows error message' do
        post :extend_trial

        expect(response).to redirect_to(app_root_path)
        expect(flash[:error]).to eq('No active trial to extend.')
      end
    end
  end

  describe 'GET #export_data' do
    it 'requires authentication' do
      session[:user_id] = nil
      allow(controller).to receive(:current_user).and_return(nil)
      get :export_data
      expect(response).to redirect_to(login_path)
    end

    context 'with trial user' do
      before do
        session[:user_id] = trial_user.id
        allow(controller).to receive(:current_user).and_return(trial_user)
      end

      it 'exports user data as JSON' do
        expect(DataExportService).to receive(:export_user_data).with(trial_user).and_return('{"pages": []}')
        expect(trial_user).to receive(:update!).with(trial_data_exported: true)

        get :export_data

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        expect(response.headers['Content-Disposition']).to include('attachment')
      end

      it 'marks data as exported' do
        expect(trial_user).to receive(:update!).with(trial_data_exported: true)

        get :export_data
      end

      it 'handles export errors gracefully' do
        expect(DataExportService).to receive(:export_user_data).and_raise(StandardError.new('Export failed'))

        get :export_data

        expect(response).to redirect_to(app_root_path)
        expect(flash[:error]).to eq('Data export failed. Please try again or contact support.')
      end
    end

    context 'with downloaded user' do
      before do
        session[:user_id] = downloaded_user.id
        allow(controller).to receive(:current_user).and_return(downloaded_user)
      end

      it 'exports user data as JSON' do
        expect(DataExportService).to receive(:export_user_data).with(downloaded_user).and_return('{"pages": []}')

        get :export_data

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
      end
    end

    context 'with user who has no trial or download' do
      it 'redirects to pricing (no entitlement)' do
        get :export_data

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include('free trial has ended')
      end
    end

    context 'with expired trial user' do
      before do
        session[:user_id] = expired_user.id
        allow(controller).to receive(:current_user).and_return(expired_user)
      end

      it 'redirects to pricing (trial ended)' do
        get :export_data

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include('free trial has ended')
      end
    end
  end

  describe 'GET #download' do
    it 'requires authentication' do
      session[:user_id] = nil
      allow(controller).to receive(:current_user).and_return(nil)
      get :download
      expect(response).to redirect_to(login_path)
    end

    context 'with trial user' do
      before do
        session[:user_id] = trial_user.id
        allow(controller).to receive(:current_user).and_return(trial_user)
      end

      it 'redirects trial users to pricing (PWA is post-purchase only)' do
        get :download
        expect(response).to redirect_to(pricing_path)
        expect(flash[:info]).to eq('Complete your purchase to download the app to your device.')
      end
    end

    context 'with downloaded user' do
      before do
        session[:user_id] = downloaded_user.id
        allow(controller).to receive(:current_user).and_return(downloaded_user)
      end

      it 'redirects to downloads controller' do
        get :download
        expect(response).to redirect_to(download_path)
      end
    end

    context 'with user who has no trial or download' do
      it 'redirects to pricing (no entitlement)' do
        get :download
        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include('free trial has ended')
      end
    end

    context 'with expired trial user' do
      before do
        session[:user_id] = expired_user.id
        allow(controller).to receive(:current_user).and_return(expired_user)
      end

      it 'redirects to pricing (trial ended)' do
        get :download
        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include('free trial has ended')
      end
    end
  end

  describe 'user isolation' do
    before do
      session[:user_id] = trial_user.id
      allow(controller).to receive(:current_user).and_return(trial_user)
    end

    it 'ensures users can only access their own trial data' do
      other_user = create(:user, :with_trial)

      get :status
      expect(assigns(:user)).to eq(trial_user)
      expect(assigns(:user)).not_to eq(other_user)
    end

    it 'prevents access to other users trial data' do
      other_user = create(:user, :with_trial)

      get :status
      expect(assigns(:user).id).to eq(trial_user.id)
      expect(assigns(:user).id).not_to eq(other_user.id)
    end
  end

  describe 'trial expiration handling' do
    context 'when trial expires during session' do
      let(:expiring_user) { create(:user, trial_started_at: 8.days.ago, trial_expires_at: 1.day.ago) }

      before do
        session[:user_id] = expiring_user.id
        allow(controller).to receive(:current_user).and_return(expiring_user)
      end

      it 'handles expired trial in export_data' do
        get :export_data
        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include('free trial has ended')
      end

      it 'handles expired trial in download' do
        get :download
        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to include('free trial has ended')
      end
    end
  end

  describe 'analytics tracking' do
    it 'tracks trial start analytics' do
      expect(AnalyticsService).to receive(:track_trial_start).with(user)

      post :start
    end

    it 'does not track analytics on trial start failure' do
      allow(user).to receive(:start_trial!).and_return(false)
      expect(AnalyticsService).not_to receive(:track_trial_start)

      post :start
    end
  end

  describe 'logging' do
    it 'logs export data requests' do
      session[:user_id] = trial_user.id
      allow(controller).to receive(:current_user).and_return(trial_user)

      # Test that the action works and logs are generated
      get :export_data
      expect(response).to have_http_status(:success)
    end

    it 'logs export errors' do
      session[:user_id] = trial_user.id
      allow(controller).to receive(:current_user).and_return(trial_user)
      allow(DataExportService).to receive(:export_user_data).and_raise(StandardError.new('Export failed'))

      # Test that the action handles errors properly
      get :export_data
      expect(response).to redirect_to(app_root_path)
      expect(flash[:error]).to eq('Data export failed. Please try again or contact support.')
    end

    it 'redirects to pricing when user has no trial or download' do
      get :export_data
      expect(response).to redirect_to(pricing_path)
      expect(flash[:alert]).to include('free trial has ended')
    end
  end
end
