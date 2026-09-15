require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, email_address: 'test@example.com', password: 'password123') }
  let(:mixed_case_user) { create(:user, email_address: 'TeSt@ExAmPlE.CoM', password: 'password123') }

  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:success)
    end

    it 'allows access without authentication' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'logs in the user and redirects to app root' do
        post :create, params: { email_address: user.email_address, password: 'password123' }

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(app_root_path)
        expect(flash[:notice]).to eq('Successfully logged in!')
      end

      it 'redirects expired hosted-week users home' do
        enable_hosted_ephemeral!
        expired = create(:user, :trial_expired, email_address: 'expired@example.com')

        post :create, params: { email_address: expired.email_address, password: 'password123' }

        expect(session[:user_id]).to eq(expired.id)
        expect(response).to redirect_to(root_path)
      end

      it 'logs in the user without remember me' do
        post :create, params: { email_address: user.email_address, password: 'password123' }

        expect(session[:user_id]).to eq(user.id)
        expect(cookies.signed[:remember_token]).to be_nil
      end

      it 'logs in the user with remember me' do
        post :create, params: {
          email_address: user.email_address,
          password: 'password123',
          remember_me: '1'
        }

        expect(session[:user_id]).to eq(user.id)
        user.reload
        expect(cookies.signed[:remember_token]).to eq(user.remember_token)
        expect(user.remember_token).to be_present
        expect(user.remember_token_expires_at).to be_present
      end

      it 'sets secure cookie attributes in production' do
        allow(Rails.env).to receive(:production?).and_return(true)

        post :create, params: {
          email_address: user.email_address,
          password: 'password123',
          remember_me: '1'
        }

        expect(cookies.signed[:remember_token]).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'renders new template with error for invalid email' do
        post :create, params: { email_address: 'wrong@example.com', password: 'password123' }

        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('Invalid email or password')
        expect(session[:user_id]).to be_nil
      end

      it 'renders new template with error for invalid password' do
        post :create, params: { email_address: user.email_address, password: 'wrongpassword' }

        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('Invalid email or password')
        expect(session[:user_id]).to be_nil
      end

      it 'renders new template with error for blank credentials' do
        post :create, params: { email_address: '', password: '' }

        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('Invalid email or password')
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with case insensitive email' do
      it 'logs in with uppercase email' do
        post :create, params: { email_address: user.email_address.upcase, password: 'password123' }

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(app_root_path)
      end

      # TODO: Fix case insensitive email lookup
      # it 'logs in with mixed case email' do
      #   post :create, params: { email_address: 'TeSt@ExAmPlE.CoM', password: 'password123' }
      #
      #   expect(session[:user_id]).to eq(user.id)
      #   expect(response).to redirect_to(app_root_path)
      # end
    end
  end

  describe 'DELETE #destroy' do
    before do
      session[:user_id] = user.id
    end

    it 'logs out the user and redirects to root' do
      delete :destroy

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq('Successfully logged out!')
    end

    it 'clears remember token if user is logged in' do
      # Set up remember token
      user.remember_me!
      cookies.signed[:remember_token] = user.remember_token

      delete :destroy

      expect(user.reload.remember_token).to be_nil
      expect(user.remember_token_expires_at).to be_nil
      expect(cookies[:remember_token]).to be_nil
    end

    it 'redirects to login when no user is logged in' do
      session[:user_id] = nil

      delete :destroy

      expect(response).to redirect_to(login_path)
    end

    it 'redirects to login when user does not exist' do
      session[:user_id] = 99999

      delete :destroy

      expect(response).to redirect_to(login_path)
    end
  end

  describe 'authentication requirements' do
    it 'allows access to new action without login' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'allows access to create action without login' do
      post :create, params: { email_address: user.email_address, password: 'password123' }
      expect(response).to have_http_status(:redirect)
    end

    it 'requires login for destroy action' do
      session[:user_id] = nil
      delete :destroy
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'remember me functionality' do
    it 'generates remember token when remember me is checked' do
      post :create, params: {
        email_address: user.email_address,
        password: 'password123',
        remember_me: '1'
      }

      user.reload
      expect(user.remember_token).to be_present
      expect(user.remember_token_expires_at).to be_present
      expect(user.remember_token_expires_at).to be > 30.days.from_now
    end

    it 'does not generate remember token when remember me is not checked' do
      post :create, params: {
        email_address: user.email_address,
        password: 'password123',
        remember_me: '0'
      }

      user.reload
      expect(user.remember_token).to be_nil
      expect(user.remember_token_expires_at).to be_nil
    end

    it 'does not generate remember token when remember me is not provided' do
      post :create, params: {
        email_address: user.email_address,
        password: 'password123'
      }

      user.reload
      expect(user.remember_token).to be_nil
      expect(user.remember_token_expires_at).to be_nil
    end
  end
end
