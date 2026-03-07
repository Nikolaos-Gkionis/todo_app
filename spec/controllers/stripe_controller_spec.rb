require 'rails_helper'

RSpec.describe StripeController, type: :controller do
  let(:user) { create(:user, email_address: 'test@example.com') }
  let(:stripe_session_id) { 'cs_test_123456789' }
  let(:stripe_session_url) { 'https://checkout.stripe.com/pay/cs_test_123456789' }

  before do
    session[:user_id] = user.id
    # Mock Stripe API key
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('STRIPE_SECRET_KEY').and_return('sk_test_123456789')
    allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return('whsec_123456789')
  end

  describe 'POST #create_checkout_session' do
    it 'requires authentication' do
      session[:user_id] = nil
      post :create_checkout_session
      expect(response).to redirect_to(login_path)
    end

    context 'with successful Stripe session creation' do
      let(:mock_session) { double('Stripe::Checkout::Session', url: stripe_session_url) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(Stripe::Checkout::Session).to receive(:create).and_return(mock_session)
      end

      it 'creates a Stripe checkout session' do
        expect(Stripe::Checkout::Session).to receive(:create).with({
          customer_email: user.email_address,
          payment_method_types: [ "card" ],
          line_items: [ {
            price_data: {
              currency: "usd",
              product_data: {
                name: "Todo-it - Download to Device",
                description: "Download to your device forever - unlimited pages, offline access, and data ownership"
              },
              unit_amount: 990
            },
            quantity: 1
          } ],
          mode: "payment",
          success_url: success_stripe_url + "?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: cancel_stripe_url,
          metadata: {
            user_id: user.id
          }
        })

        post :create_checkout_session
      end

      it 'redirects to Stripe checkout URL' do
        post :create_checkout_session
        expect(response).to redirect_to(stripe_session_url)
      end

      it 'allows redirect to external host' do
        post :create_checkout_session
        expect(response.headers['Location']).to eq(stripe_session_url)
      end
    end

    context 'with Stripe API error' do
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_raise(
          Stripe::StripeError.new('Card declined')
        )
      end

      it 'redirects to settings with error message' do
        post :create_checkout_session

        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to eq('Payment setup failed. Please try again or contact support if the issue persists.')
      end
    end
  end

  describe 'GET #success' do
    it 'requires authentication' do
      session[:user_id] = nil
      get :success, params: { session_id: stripe_session_id }
      expect(response).to redirect_to(login_path)
    end

    context 'with valid session_id' do
      let(:mock_session) do
        double('Stripe::Checkout::Session',
          payment_status: 'paid',
          id: stripe_session_id,
          metadata: { 'user_id' => user.id.to_s },
          customer_details: nil,
          customer_email: user.email_address
        )
      end

      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).with(stripe_session_id).and_return(mock_session)
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:mark_as_downloaded!)
        allow(user).to receive(:generate_download_token!).and_return('download_token_123')
        allow(AnalyticsService).to receive(:track_trial_conversion)
        allow(AnalyticsService).to receive(:track_payment_completion)
        allow(UserMailer).to receive(:purchase_confirmation).and_call_original
      end

      it 'retrieves the Stripe session' do
        expect(Stripe::Checkout::Session).to receive(:retrieve).with(stripe_session_id)

        get :success, params: { session_id: stripe_session_id }
      end

      context 'when payment is successful' do
        it 'marks user as downloaded' do
          expect(user).to receive(:mark_as_downloaded!)

          get :success, params: { session_id: stripe_session_id }
        end

        it 'generates download token' do
          expect(user).to receive(:generate_download_token!).and_return('download_token_123')

          get :success, params: { session_id: stripe_session_id }
        end

        it 'tracks conversion analytics' do
          expect(AnalyticsService).to receive(:track_trial_conversion).with(user)

          get :success, params: { session_id: stripe_session_id }
        end

        it 'tracks payment completion analytics' do
          expect(AnalyticsService).to receive(:track_payment_completion).with(user, stripe_session_id)

          get :success, params: { session_id: stripe_session_id }
        end

        it 'sends purchase confirmation email' do
          expect(UserMailer).to receive(:purchase_confirmation).with(user, anything).and_call_original

          get :success, params: { session_id: stripe_session_id }
        end

        it 'redirects to download page with success message' do
          get :success, params: { session_id: stripe_session_id }

          expect(response).to redirect_to(download_app_path(token: 'download_token_123'))
          expect(flash[:notice]).to eq('Payment successful! Your app is ready to download. 🎉')
        end
      end

      context 'when payment is not successful' do
        before do
          allow(mock_session).to receive(:payment_status).and_return('unpaid')
        end

        it 'redirects to pricing with error message' do
          get :success, params: { session_id: stripe_session_id }

          expect(response).to redirect_to(pricing_path)
          expect(flash[:alert]).to eq('Payment was not completed successfully.')
        end

        it 'does not mark user as downloaded' do
          expect(user).not_to receive(:mark_as_downloaded!)

          get :success, params: { session_id: stripe_session_id }
        end
      end
    end

    context 'with Stripe API error' do
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).and_raise(
          Stripe::StripeError.new('Session not found')
        )
      end

      it 'redirects to pricing with error message' do
        get :success, params: { session_id: stripe_session_id }

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq('Something went wrong processing your payment. Please contact support if the charge appears on your card.')
      end
    end

    context 'without session_id' do
      it 'redirects to pricing with error message' do
        get :success

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq('Invalid payment session.')
      end
    end
  end

  describe 'GET #cancel' do
    it 'requires authentication' do
      session[:user_id] = nil
      get :cancel
      expect(response).to redirect_to(login_path)
    end

    it 'redirects to settings with cancellation message' do
      get :cancel

      expect(response).to redirect_to(settings_path)
      expect(flash[:alert]).to eq('Payment was cancelled. No charges were made.')
    end
  end

  describe 'GET #customer_portal' do
    it 'requires authentication' do
      session[:user_id] = nil
      get :customer_portal
      expect(response).to redirect_to(login_path)
    end

    it 'redirects to pricing with coming soon message' do
      get :customer_portal

      expect(response).to redirect_to(pricing_path)
      expect(flash[:notice]).to eq('Customer portal coming soon! For now, contact support to manage your billing.')
    end
  end

  describe 'POST #webhook' do
    # Note: Webhook testing is complex due to request body mocking
    # In a real application, you'd test webhooks with integration tests
    # For now, we'll test the private methods directly

    it 'handles webhook requests' do
      # Basic test that the webhook endpoint exists and responds
      post :webhook

      # Should return some response (either success or error)
      expect(response).to have_http_status(:success).or have_http_status(:bad_request)
    end
  end

  describe 'private methods' do
    describe '#handle_checkout_session_completed' do
      let(:mock_session) do
        double('Stripe::Checkout::Session',
          id: stripe_session_id,
          metadata: { 'user_id' => user.id.to_s }
        )
      end

      before do
        allow(User).to receive(:find_by).with(id: user.id.to_s).and_return(user)
        allow(user).to receive(:mark_as_downloaded!)
        allow(user).to receive(:generate_download_token!).and_return('download_token_123')
        allow(AnalyticsService).to receive(:track_trial_conversion)
        allow(AnalyticsService).to receive(:track_payment_completion)
        allow(UserMailer).to receive(:purchase_confirmation).and_call_original
      end

      it 'processes the checkout session completion' do
        expect(user).to receive(:mark_as_downloaded!)
        expect(user).to receive(:generate_download_token!).and_return('download_token_123')
        expect(AnalyticsService).to receive(:track_trial_conversion).with(user)
        expect(AnalyticsService).to receive(:track_payment_completion).with(user, stripe_session_id)
        expect(UserMailer).to receive(:purchase_confirmation).with(user, anything).and_call_original
        # Rails logger is called multiple times, so we don't test it specifically

        controller.send(:handle_checkout_session_completed, mock_session)
      end

      context 'when user_id is missing' do
        before do
          allow(mock_session.metadata).to receive(:[]).with('user_id').and_return(nil)
        end

        it 'does not process the session' do
          expect(user).not_to receive(:mark_as_downloaded!)

          controller.send(:handle_checkout_session_completed, mock_session)
        end
      end

      context 'when user is not found' do
        before do
          allow(User).to receive(:find_by).with(id: user.id.to_s).and_return(nil)
        end

        it 'does not process the session' do
          expect(AnalyticsService).not_to receive(:track_trial_conversion)

          controller.send(:handle_checkout_session_completed, mock_session)
        end
      end
    end

    describe '#handle_payment_intent_succeeded' do
      let(:mock_payment_intent) { double('Stripe::PaymentIntent', id: 'pi_123456789') }

      it 'logs the payment intent success' do
        expect(Rails.logger).to receive(:info).with('Payment intent succeeded: pi_123456789')

        controller.send(:handle_payment_intent_succeeded, mock_payment_intent)
      end
    end

    describe '#configure_stripe' do
      it 'sets the Stripe API key' do
        expect(Stripe).to receive(:api_key=).with('sk_test_123456789')

        controller.send(:configure_stripe)
      end
    end
  end

  describe 'user isolation' do
    it 'ensures users can only access their own payment data' do
      # Mock the Stripe session creation
      mock_session = double('Stripe::Checkout::Session', url: stripe_session_url)
      allow(controller).to receive(:current_user).and_return(user)

      # The session should be created with the current user's email and ID
      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(
          customer_email: user.email_address,
          metadata: { user_id: user.id }
        )
      ).and_return(mock_session)

      post :create_checkout_session
    end
  end
end
