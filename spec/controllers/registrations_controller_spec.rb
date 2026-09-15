require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
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

    it 'initializes a new user instance' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    let(:valid_user_params) do
      {
        name: 'John Doe',
        email_address: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    let(:invalid_user_params) do
      {
        name: '',
        email_address: 'invalid-email',
        password: '123',
        password_confirmation: 'different'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :create, params: { user: valid_user_params }
        }.to change(User, :count).by(1)
      end

      it 'logs in the user automatically' do
        post :create, params: { user: valid_user_params }

        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'does not start a hosted week on self-host' do
        post :create, params: { user: valid_user_params }

        user = User.last
        expect(user.trial_started?).to be false
        expect(user.can_use_app?).to be true
      end

      it 'starts a hosted week when HOSTED_EPHEMERAL is on' do
        enable_hosted_ephemeral!
        post :create, params: { user: valid_user_params }

        user = User.last
        expect(user.trial_started?).to be true
        expect(user.trial_active?).to be true
      end

      it 'sends welcome email' do
        expect(UserMailer).to receive(:welcome_trial).and_call_original

        post :create, params: { user: valid_user_params }
      end

      it 'redirects to app root with success message' do
        post :create, params: { user: valid_user_params }

        expect(response).to redirect_to(app_root_path)
        expect(flash[:notice]).to eq('Account created. This instance is yours.')
      end

      it 'creates user with correct attributes' do
        post :create, params: { user: valid_user_params }

        user = User.last
        expect(user.name).to eq('John Doe')
        expect(user.email_address).to eq('john@example.com')
        expect(user.authenticate('password123')).to be_truthy
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new user' do
        expect {
          post :create, params: { user: invalid_user_params }
        }.not_to change(User, :count)
      end

      it 'renders new template with errors' do
        post :create, params: { user: invalid_user_params }

        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not log in the user' do
        post :create, params: { user: invalid_user_params }

        expect(session[:user_id]).to be_nil
      end

      it 'does not start trial' do
        post :create, params: { user: invalid_user_params }

        expect(User.count).to eq(0)
      end

      it 'does not send welcome email' do
        expect(UserMailer).not_to receive(:welcome_trial)

        post :create, params: { user: invalid_user_params }
      end

      it 'assigns user with errors' do
        post :create, params: { user: invalid_user_params }

        expect(assigns(:user)).to be_a(User)
        expect(assigns(:user)).not_to be_valid
        expect(assigns(:user).errors).not_to be_empty
      end
    end

    context 'with duplicate email' do
      before do
        create(:user, email_address: 'john@example.com')
      end

      it 'does not create a duplicate user' do
        expect {
          post :create, params: { user: valid_user_params }
        }.not_to change(User, :count)
      end

      it 'renders new template with errors' do
        post :create, params: { user: valid_user_params }

        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'shows email uniqueness error' do
        post :create, params: { user: valid_user_params }

        expect(assigns(:user).errors[:email_address]).to include('has already been taken')
      end
    end

    context 'with missing required fields' do
      it 'validates name presence' do
        params = valid_user_params.merge(name: '')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:name]).to include("can't be blank")
      end

      it 'validates email presence' do
        params = valid_user_params.merge(email_address: '')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:email_address]).to include("can't be blank")
      end

      it 'validates password presence' do
        params = valid_user_params.merge(password: '')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:password]).to include("can't be blank")
      end

      it 'validates password confirmation' do
        params = valid_user_params.merge(password_confirmation: 'different')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:password_confirmation]).to include("doesn't match Password")
      end
    end

    context 'with invalid email format' do
      it 'validates email format' do
        params = valid_user_params.merge(email_address: 'invalid-email')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:email_address]).to include('is invalid')
      end
    end

    context 'with short password' do
      it 'validates minimum password length' do
        params = valid_user_params.merge(password: '123', password_confirmation: '123')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:password]).to include('is too short (minimum is 6 characters)')
      end
    end

    context 'with short name' do
      it 'validates minimum name length' do
        params = valid_user_params.merge(name: 'A')
        post :create, params: { user: params }

        expect(assigns(:user).errors[:name]).to include('is too short (minimum is 2 characters)')
      end
    end

    context 'with long name' do
      it 'validates maximum name length' do
        long_name = 'A' * 51
        params = valid_user_params.merge(name: long_name)
        post :create, params: { user: params }

        expect(assigns(:user).errors[:name]).to include('is too long (maximum is 50 characters)')
      end
    end

    context 'hosted week on peponi.to' do
      before { enable_hosted_ephemeral! }

      it 'sets trial start date' do
        Timecop.freeze do
          post :create, params: { user: valid_user_params }

          user = User.last
          expect(user.trial_started_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'sets trial expiration date' do
        Timecop.freeze do
          post :create, params: { user: valid_user_params }

          user = User.last
          expect(user.trial_expires_at).to be_within(1.second).of(7.days.from_now)
        end
      end

      it 'sets device downloaded to false' do
        post :create, params: { user: valid_user_params }

        user = User.last
        expect(user.device_downloaded?).to be false
      end
    end
  end

  describe 'authentication requirements' do
    let(:valid_user_params) do
      {
        name: 'John Doe',
        email_address: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    it 'allows access to new action without login' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'allows access to create action without login' do
      post :create, params: { user: valid_user_params }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'parameter filtering' do
    let(:valid_user_params) do
      {
        name: 'John Doe',
        email_address: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    it 'only permits allowed parameters' do
      malicious_params = valid_user_params.merge(
        admin: true,
        role: 'admin',
        malicious_field: 'hack_attempt'
      )

      post :create, params: { user: malicious_params }

      user = User.last
      expect(user.respond_to?(:admin)).to be false
      expect(user.respond_to?(:role)).to be false
      expect(user.respond_to?(:malicious_field)).to be false
    end
  end

  describe 'email case sensitivity' do
    let(:valid_user_params) do
      {
        name: 'John Doe',
        email_address: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    it 'creates user with uppercase email' do
      params = valid_user_params.merge(email_address: 'JOHN@EXAMPLE.COM')
      post :create, params: { user: params }

      user = User.last
      expect(user.email_address).to eq('JOHN@EXAMPLE.COM')
    end
  end

  describe 'password security' do
    let(:valid_user_params) do
      {
        name: 'John Doe',
        email_address: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    it 'encrypts password' do
      post :create, params: { user: valid_user_params }

      user = User.last
      expect(user.password_digest).not_to eq('password123')
      expect(user.password_digest).to be_present
    end

    it 'does not store plain text password' do
      post :create, params: { user: valid_user_params }

      user = User.last
      expect(user.password).to be_nil
    end
  end
end
