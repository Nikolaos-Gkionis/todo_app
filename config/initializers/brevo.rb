# frozen_string_literal: true

# Configure Brevo API client with a 30-second timeout to avoid "execution expired"
# when the droplet has slower connectivity to api.brevo.com.
Rails.application.config.to_prepare do
  BrevoRails::ActionMailer::DeliveryMethod.class_eval do
    def configuration
      @configuration ||= Brevo::Configuration.new.tap do |config|
        config.api_key["api-key"] = settings.fetch(:api_key)
        config.debugging = settings.fetch(:debugging, false)
        config.timeout = settings.fetch(:timeout, 30)
      end
    end
  end
rescue NameError, LoadError => e
  Rails.logger.warn "Brevo timeout patch skipped: #{e.message}"
end
