require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'GET #new' do
    it 'renders the signup page' do
      get :new
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end

    context 'when user is already logged in' do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it 'redirects to app root' do
        get :new
        expect(response).to redirect_to(app_root_path)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      let(:valid_attributes) do
        {
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'starts a trial for the new user' do
        post :create, params: { user: valid_attributes }

        user = User.last
        expect(user.trial_started_at).to be_present
        expect(user.trial_expires_at).to be_present
        expect(user.trial_expires_at).to be_within(1.second).of(user.trial_started_at + 7.days)
      end

      it 'sends welcome email' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to have_enqueued_mail(UserMailer, :welcome_trial)
      end

      it 'redirects to app root' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(app_root_path)
      end

      it 'shows success message' do
        post :create, params: { user: valid_attributes }
        expect(flash[:success]).to include('7-day free trial has started')
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) do
        {
          name: '',
          email: 'invalid-email',
          password: '123',
          password_confirmation: '456'
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'renders the signup page' do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
      end

      it 'shows error messages' do
        post :create, params: { user: invalid_attributes }
        expect(assigns(:user).errors).not_to be_empty
      end
    end

    context 'with duplicate email' do
      let!(:existing_user) { create(:user, email: 'existing@example.com') }
      let(:duplicate_attributes) do
        {
          name: 'John Doe',
          email: 'existing@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: { user: duplicate_attributes }
        }.not_to change(User, :count)
      end

      it 'shows email taken error' do
        post :create, params: { user: duplicate_attributes }
        expect(assigns(:user).errors[:email]).to include('has already been taken')
      end
    end
  end
end
