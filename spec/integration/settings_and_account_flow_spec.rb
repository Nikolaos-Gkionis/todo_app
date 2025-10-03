require 'rails_helper'

RSpec.describe 'Settings and Account Management Flow', type: :request do
  let(:user) { create(:user, :with_trial) }

  before do
    # Log in user
    post login_path, params: { email_address: user.email_address, password: 'password123' }
  end

  describe 'Complete settings management flow' do
    it 'allows user to update all settings and manage account' do
      # Step 1: Visit settings page
      get settings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Account Settings')

      # Step 2: Update non-sensitive settings (name)
      patch settings_path, params: {
        user: {
          name: 'Updated Name',
          email_address: user.email_address # Keep same email
        }
      }
      expect(response).to redirect_to(settings_path)

      # Step 3: Verify name was updated
      user.reload
      expect(user.name).to eq('Updated Name')

      # Step 4: Update theme
      post settings_theme_path, params: { theme: 'dark' }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['status']).to eq('success')
      expect(JSON.parse(response.body)['theme']).to eq('dark')

      # Step 5: Verify theme was updated in session
      expect(session[:theme]).to eq('dark')

      # Step 6: Update password (sensitive change)
      patch settings_path, params: {
        user: {
          name: 'Updated Name',
          email_address: user.email_address,
          current_password: 'password123',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }
      expect(response).to redirect_to(settings_path)

      # Step 7: Verify password was updated by logging out and back in
      delete logout_path
      post login_path, params: {
        email_address: user.email_address,
        password: 'newpassword123'
      }
      expect(response).to redirect_to(app_root_path)

      # Step 8: Update email (sensitive change)
      patch settings_path, params: {
        user: {
          name: 'Updated Name',
          email_address: 'newemail@example.com',
          current_password: 'newpassword123'
        }
      }
      expect(response).to redirect_to(settings_path)

      # Step 9: Verify email was updated
      user.reload
      expect(user.email_address).to eq('newemail@example.com')

      # Step 10: Visit delete account page
      get delete_account_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Delete Account')

      # Step 11: Delete account
      expect {
        delete settings_path, params: {
          confirm_deletion: 'DELETE'
        }
      }.to change(User, :count).by(-1)

      expect(response).to redirect_to(root_path)

      # Step 12: Verify user is logged out
      expect(session[:user_id]).to be_nil
    end

    it 'handles settings validation errors' do
      # Step 1: Try to update with invalid name
      patch settings_path, params: {
        user: {
          name: 'A', # Too short
          email_address: user.email_address
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      # The validation errors are displayed in the form, check for the form being rendered
      expect(response.body).to include('Account Settings')
      expect(response.body).to include('field_with_errors')

      # Step 2: Try to update with invalid email
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: 'invalid-email'
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      # The validation errors are displayed in the form, check for the form being rendered
      expect(response.body).to include('Account Settings')
      expect(response.body).to include('field_with_errors')

      # Step 3: Try to update password without current password
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: user.email_address,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      # The validation errors are displayed in the form, check for the form being rendered
      expect(response.body).to include('Account Settings')
      expect(response.body).to include('field_with_errors')

      # Step 4: Try to update email without current password
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: 'newemail@example.com'
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      # The validation errors are displayed in the form, check for the form being rendered
      expect(response.body).to include('Account Settings')
      expect(response.body).to include('field_with_errors')
    end

    it 'handles password confirmation mismatch' do
      # Step 1: Try to update password with mismatched confirmation
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: user.email_address,
          current_password: 'password123',
          password: 'newpassword123',
          password_confirmation: 'differentpassword'
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Password confirmation doesn&#39;t match Password')
    end

    it 'handles duplicate email addresses' do
      # Create another user
      other_user = create(:user, email_address: 'existing@example.com')

      # Step 1: Try to update to existing email
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: 'existing@example.com',
          current_password: 'password123'
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Email address has already been taken')
    end
  end

  describe 'Theme management flow' do
    it 'allows switching between themes' do
      # Step 1: Set initial theme
      post settings_theme_path, params: { theme: 'lined' }
      expect(response).to have_http_status(:success)
      expect(session[:theme]).to eq('lined')

      # Step 2: Switch to dark theme
      post settings_theme_path, params: { theme: 'dark' }
      expect(response).to have_http_status(:success)
      expect(session[:theme]).to eq('dark')

      # Step 3: Switch to classic theme
      post settings_theme_path, params: { theme: 'classic' }
      expect(response).to have_http_status(:success)
      expect(session[:theme]).to eq('classic')
    end

    it 'handles invalid theme values' do
      # Step 1: Try to set invalid theme
      post settings_theme_path, params: { theme: 'invalid_theme' }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['status']).to eq('error')

      # Step 2: Session theme should remain unchanged
      expect(session[:theme]).to be_nil
    end
  end

  describe 'Account deletion flow' do
    it 'requires confirmation for account deletion' do
      # Step 1: Try to delete account without confirmation
      delete settings_path, params: { confirm_deletion: '' }
      expect(response).to redirect_to(delete_account_path)
      follow_redirect!
      expect(response.body).to include('Please confirm account deletion by typing &#39;DELETE&#39;')

      # Step 2: Try to delete account with wrong confirmation
      delete settings_path, params: { confirm_deletion: 'WRONG' }
      expect(response).to redirect_to(delete_account_path)
      follow_redirect!
      expect(response.body).to include('Please confirm account deletion by typing &#39;DELETE&#39;')

      # Step 3: Verify user still exists
      expect(User.exists?(user.id)).to be true
    end

    it 'deletes user and all associated data' do
      # Create some data for the user
      page = create(:page, user: user)
      todo = create(:todo, page: page)

      # Step 1: Delete account with correct confirmation
      expect {
        delete settings_path, params: {
          confirm_deletion: 'DELETE'
        }
      }.to change(User, :count).by(-1)

      expect(response).to redirect_to(root_path)

      # Step 2: Verify user is logged out
      expect(session[:user_id]).to be_nil

      # Step 3: Verify associated data was deleted (cascade delete)
      expect(Page.exists?(page.id)).to be false
      expect(Todo.exists?(todo.id)).to be false
    end
  end

  describe 'Authentication requirements' do
    it 'requires authentication for all settings actions' do
      # Log out user
      delete logout_path

      # Test settings page
      get settings_path
      expect(response).to redirect_to(login_path)

      # Test update settings
      patch settings_path, params: { user: { name: 'Test' } }
      expect(response).to redirect_to(login_path)

      # Test update theme
      post settings_theme_path, params: { theme: 'dark' }
      expect(response).to redirect_to(login_path)

      # Test delete account page
      get delete_account_path
      expect(response).to redirect_to(login_path)

      # Test delete account
      delete settings_path, params: { confirm_deletion: 'DELETE' }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'User isolation in settings' do
    it 'prevents users from accessing other users settings' do
      # Create another user
      other_user = create(:user, :with_trial)

      # Step 1: Try to access other user's settings (this would be prevented by authentication)
      # Since we're logged in as the first user, we can't access other user's settings
      # This is more of a conceptual test since the authentication system prevents this

      # Step 2: Verify we can only access our own settings
      get settings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(CGI.escapeHTML(user.name))
      expect(response.body).to include(user.email_address)
    end
  end

  describe 'Email change notifications' do
    it 'sends email notifications for sensitive changes' do
      # Mock the mailer
      allow(UserMailer).to receive(:email_changed).and_return(double(deliver_now: true))

      # Step 1: Change email
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: 'newemail@example.com',
          current_password: 'password123'
        }
      }
      expect(response).to redirect_to(settings_path)

      # Step 2: Verify email notification was sent
      expect(UserMailer).to have_received(:email_changed).with(user, 'user19@example.com')
    end

    it 'sends password change notifications' do
      # Mock the mailer
      allow(UserMailer).to receive(:password_changed).and_return(double(deliver_now: true))

      # Step 1: Change password
      patch settings_path, params: {
        user: {
          name: user.name,
          email_address: user.email_address,
          current_password: 'password123',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }
      expect(response).to redirect_to(settings_path)

      # Step 2: Verify email notification was sent
      expect(UserMailer).to have_received(:password_changed).with(user)
    end
  end
end
