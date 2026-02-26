# frozen_string_literal: true

# Configure Brevo API client with a 30-second timeout to avoid "execution expired"
# when the droplet has slower connectivity to api.brevo.com.
# The brevo-rails gem doesn't expose timeout in brevo_settings, so we patch the
# configuration here.
Rails.application.config.to_prepare do
  BrevoRails::ActionMailer::DeliveryMethod.class_eval do
    def configuration
      @configuration ||= Brevo::Configuration.new.tap do |config|
        config.api_key["api-key"] = settings.fetch(:api_key)
        config.debugging = settings.fetch(:debugging, false)
        # Prevent "execution expired" - give Brevo API more time to respond
        config.timeout = settings.fetch(:timeout, 30)
      end
    end
  end
end
