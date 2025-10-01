require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'GET #new' do
    it 'renders the login page' do
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
    let(:user) { create(:user, password: 'password123') }

    context 'with valid credentials' do
      it 'logs in the user' do
        post :create, params: { email: user.email_address, password: 'password123' }

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(app_root_path)
      end

      it 'shows success message' do
        post :create, params: { email: user.email_address, password: 'password123' }

        expect(flash[:success]).to include('Logged in successfully')
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user' do
        post :create, params: { email: user.email_address, password: 'wrong_password' }

        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
      end

      it 'shows error message' do
        post :create, params: { email: user.email_address, password: 'wrong_password' }

        expect(flash[:alert]).to include('Invalid email or password')
      end
    end

    context 'with non-existent email' do
      it 'does not log in the user' do
        post :create, params: { email: 'nonexistent@example.com', password: 'password123' }

        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it 'logs out the user' do
      delete :destroy

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it 'shows logout message' do
      delete :destroy

      expect(flash[:success]).to include('Logged out successfully')
    end
  end
end
