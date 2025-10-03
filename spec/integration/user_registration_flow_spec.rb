require 'rails_helper'

RSpec.describe 'User Registration Flow', type: :request do
  describe 'Complete user registration and onboarding' do
    it 'allows new user to register and start using the app' do
      # Step 1: Visit signup page
      get signup_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Create your account')

      # Step 2: Submit registration form
      user_params = {
        user: {
          name: 'Test User',
          email_address: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      expect {
        post signup_path, params: user_params
      }.to change(User, :count).by(1)

      # Step 3: Should be redirected to app root after successful registration
      expect(response).to redirect_to(app_root_path)
      follow_redirect!

      # Step 4: Should be on the app root page (pages index)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('My Pages')

      # Step 5: User should be automatically logged in
      user = User.find_by(email_address: 'test@example.com')
      expect(session[:user_id]).to eq(user.id)

      # Step 6: User should have an active trial
      expect(user.trial_active?).to be true
      expect(user.trial_started_at).to be_present
      expect(user.trial_expires_at).to be_present
    end

    it 'handles registration with invalid data' do
      # Step 1: Visit signup page
      get signup_path
      expect(response).to have_http_status(:success)

      # Step 2: Submit invalid registration data
      invalid_params = {
        user: {
          name: '',
          email_address: 'invalid-email',
          password: '123',
          password_confirmation: '456'
        }
      }

      expect {
        post signup_path, params: invalid_params
      }.not_to change(User, :count)

      # Step 3: Should render signup form again with errors
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Create your account')
    end

    it 'prevents duplicate email registration' do
      # Create existing user
      create(:user, email_address: 'existing@example.com')

      # Step 1: Try to register with same email
      duplicate_params = {
        user: {
          name: 'Another User',
          email_address: 'existing@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      expect {
        post signup_path, params: duplicate_params
      }.not_to change(User, :count)

      # Step 2: Should render signup form with error
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Email address has already been taken')
    end
  end

  describe 'User login flow' do
    let!(:user) { create(:user, email_address: 'login@example.com', password: 'password123') }

    it 'allows existing user to log in' do
      # Step 1: Visit login page
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Sign in to your account')

      # Step 2: Submit login form
      login_params = {
        email_address: 'login@example.com',
        password: 'password123'
      }

      post login_path, params: login_params

      # Step 3: Should be redirected to app root
      expect(response).to redirect_to(app_root_path)
      follow_redirect!

      # Step 4: Should be on the app root page
      expect(response).to have_http_status(:success)
      expect(response.body).to include('My Pages')

      # Step 5: User should be logged in
      expect(session[:user_id]).to eq(user.id)
    end

    it 'handles login with invalid credentials' do
      # Step 1: Visit login page
      get login_path
      expect(response).to have_http_status(:success)

      # Step 2: Submit invalid credentials
      invalid_params = {
        email_address: 'login@example.com',
        password: 'wrongpassword'
      }

      post login_path, params: invalid_params

      # Step 3: Should render login form with error
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Invalid email or password')
      expect(session[:user_id]).to be_nil
    end

    it 'handles case-insensitive email login' do
      # Step 1: Login with uppercase email
      login_params = {
        email_address: 'LOGIN@EXAMPLE.COM',
        password: 'password123'
      }

      post login_path, params: login_params

      # Step 2: Should successfully log in
      expect(response).to redirect_to(app_root_path)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe 'User logout flow' do
    let(:user) { create(:user) }

    before do
      # Log in user
      post login_path, params: { email_address: user.email_address, password: 'password123' }
    end

    it 'allows logged in user to log out' do
      # Step 1: Should be logged in
      expect(session[:user_id]).to eq(user.id)

      # Step 2: Log out
      delete logout_path

      # Step 3: Should be redirected to login page
      expect(response).to redirect_to(login_path)
      follow_redirect!

      # Step 4: Should be on login page
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Sign in to your account')

      # Step 5: Session should be cleared
      expect(session[:user_id]).to be_nil
    end
  end
end
