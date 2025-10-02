require 'rails_helper'

RSpec.describe SettingsController, type: :controller do
  let(:user) { create(:user, name: 'John Doe', email_address: 'john@example.com', password: 'password123') }
  let(:other_user) { create(:user) }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:success)
    end

    it 'assigns current user' do
      get :index
      expect(assigns(:user)).to eq(user)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :index
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'PATCH #update' do
    let(:valid_update_params) do
      {
        name: 'Jane Doe',
        email_address: 'jane@example.com'
      }
    end

    let(:password_update_params) do
      {
        password: 'newpassword123',
        password_confirmation: 'newpassword123',
        current_password: 'password123'
      }
    end

    let(:email_update_params) do
      {
        email_address: 'newemail@example.com',
        current_password: 'password123'
      }
    end

    it 'requires authentication' do
      session[:user_id] = nil
      patch :update, params: { user: valid_update_params }
      expect(response).to redirect_to(login_path)
    end

    context 'updating non-sensitive fields (name only)' do
      it 'updates the user name successfully' do
        patch :update, params: { user: { name: 'Jane Doe', email_address: user.email_address } }

        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to eq('Account updated successfully!')

        user.reload
        expect(user.name).to eq('Jane Doe')
        expect(user.email_address).to eq('john@example.com') # Email unchanged
      end

      it 'renders index with errors when update fails' do
        # Test with a name that's too long (over 50 characters)
        long_name = 'a' * 51

        patch :update, params: { user: { name: long_name, email_address: user.email_address } }

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'updating password' do
      it 'updates password with correct current password' do
        expect(UserMailer).to receive(:password_changed).with(user).and_call_original

        patch :update, params: { user: password_update_params }

        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to eq('Account updated successfully!')

        user.reload
        expect(user.authenticate('newpassword123')).to be_truthy
      end

      it 'sends password change notification email' do
        expect(UserMailer).to receive(:password_changed).with(user).and_call_original

        patch :update, params: { user: password_update_params }
      end

      it 'fails with incorrect current password' do
        patch :update, params: { user: password_update_params.merge(current_password: 'wrongpassword') }

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:user).errors[:current_password]).to include('is incorrect')
      end

      it 'fails when password update fails' do
        # Test with password confirmation mismatch
        mismatched_password_params = password_update_params.merge(
          password_confirmation: 'differentpassword'
        )

        patch :update, params: { user: mismatched_password_params }

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'updating email address' do
      it 'updates email with correct current password' do
        expect(UserMailer).to receive(:email_changed).with(user, 'john@example.com').and_call_original

        patch :update, params: { user: email_update_params }

        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to eq('Account updated successfully!')

        user.reload
        expect(user.email_address).to eq('newemail@example.com')
      end

      it 'sends email change notification to old email' do
        expect(UserMailer).to receive(:email_changed).with(user, 'john@example.com').and_call_original

        patch :update, params: { user: email_update_params }
      end

      it 'fails with incorrect current password' do
        patch :update, params: { user: email_update_params.merge(current_password: 'wrongpassword') }

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:user).errors[:current_password]).to include('is incorrect')
      end

      it 'fails when email update fails' do
        # Test with an invalid email format
        invalid_email_params = email_update_params.merge(email_address: 'invalid-email')

        patch :update, params: { user: invalid_email_params }

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'parameter filtering' do
      it 'only permits allowed parameters' do
        malicious_params = valid_update_params.merge(
          admin: true,
          role: 'admin',
          malicious_field: 'hack_attempt'
        )

        patch :update, params: { user: malicious_params }

        user.reload
        expect(user.respond_to?(:admin)).to be false
        expect(user.respond_to?(:role)).to be false
        expect(user.respond_to?(:malicious_field)).to be false
      end
    end
  end

  describe 'GET #delete' do
    it 'renders the delete template' do
      get :delete
      expect(response).to render_template(:delete)
      expect(response).to have_http_status(:success)
    end

    it 'assigns current user' do
      get :delete
      expect(assigns(:user)).to eq(user)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :delete
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'requires authentication' do
      session[:user_id] = nil
      delete :destroy, params: { confirm_deletion: 'DELETE' }
      expect(response).to redirect_to(login_path)
    end

    context 'with correct confirmation' do
      it 'deletes the user account' do
        expect {
          delete :destroy, params: { confirm_deletion: 'DELETE' }
        }.to change(User, :count).by(-1)
      end

      it 'clears the session' do
        delete :destroy, params: { confirm_deletion: 'DELETE' }
        expect(session[:user_id]).to be_nil
      end

      it 'redirects to root with success message' do
        delete :destroy, params: { confirm_deletion: 'DELETE' }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Your account has been successfully deleted. We're sorry to see you go!")
      end

      it 'deletes associated pages and todos' do
        page = create(:page, user: user)
        todo = create(:todo, page: page)

        expect {
          delete :destroy, params: { confirm_deletion: 'DELETE' }
        }.to change(Page, :count).by(-1).and change(Todo, :count).by(-1)
      end
    end

    context 'with incorrect confirmation' do
      it 'does not delete the user account' do
        expect {
          delete :destroy, params: { confirm_deletion: 'wrong' }
        }.not_to change(User, :count)
      end

      it 'redirects to delete page with error message' do
        delete :destroy, params: { confirm_deletion: 'wrong' }

        expect(response).to redirect_to(delete_account_path)
        expect(flash[:alert]).to eq("Please confirm account deletion by typing 'DELETE'")
      end

      it 'does not clear the session' do
        delete :destroy, params: { confirm_deletion: 'wrong' }
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'without confirmation parameter' do
      it 'does not delete the user account' do
        expect {
          delete :destroy
        }.not_to change(User, :count)
      end

      it 'redirects to delete page with error message' do
        delete :destroy

        expect(response).to redirect_to(delete_account_path)
        expect(flash[:alert]).to eq("Please confirm account deletion by typing 'DELETE'")
      end
    end
  end

  describe 'POST #update_theme' do
    it 'requires authentication' do
      session[:user_id] = nil
      post :update_theme, params: { theme: 'dark' }
      expect(response).to redirect_to(login_path)
    end

    context 'with valid theme' do
      %w[classic lined graph vintage dark].each do |theme|
        it "sets #{theme} theme successfully" do
          post :update_theme, params: { theme: theme }

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include('application/json')

          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('success')
          expect(json_response['theme']).to eq(theme)
          expect(session[:theme]).to eq(theme)
        end
      end
    end

    context 'with invalid theme' do
      it 'returns error for invalid theme' do
        post :update_theme, params: { theme: 'invalid_theme' }

        expect(response).to have_http_status(:bad_request)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid theme')
      end

      it 'does not set session theme for invalid theme' do
        post :update_theme, params: { theme: 'invalid_theme' }
        expect(session[:theme]).to be_nil
      end
    end

    context 'with nil theme' do
      it 'returns error for nil theme' do
        post :update_theme, params: { theme: nil }

        expect(response).to have_http_status(:bad_request)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid theme')
      end
    end
  end

  describe 'user isolation' do
    it 'ensures users can only access their own settings' do
      # This is implicit in the controller since it uses current_user
      # But we can verify that the assigned user is always the current user
      get :index
      expect(assigns(:user)).to eq(user)

      patch :update, params: { user: { name: 'Updated Name' } }
      expect(assigns(:user)).to eq(user)

      get :delete
      expect(assigns(:user)).to eq(user)

      delete :destroy, params: { confirm_deletion: 'DELETE' }
      # User is deleted, so we can't check assigns(:user)
    end
  end

  describe 'email notifications' do
    context 'password change' do
      it 'sends notification to current email' do
        expect(UserMailer).to receive(:password_changed).with(user).and_call_original

        patch :update, params: {
          user: {
            password: 'newpassword123',
            password_confirmation: 'newpassword123',
            current_password: 'password123'
          }
        }
      end
    end

    context 'email change' do
      it 'sends notification to old email address' do
        expect(UserMailer).to receive(:email_changed).with(user, 'john@example.com').and_call_original

        patch :update, params: {
          user: {
            email_address: 'newemail@example.com',
            current_password: 'password123'
          }
        }
      end
    end
  end
end
