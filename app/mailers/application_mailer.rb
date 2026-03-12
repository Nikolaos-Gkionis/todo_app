class ApplicationMailer < ActionMailer::Base
  default from: "Peponi.to <noreply@peponi.to>"
  layout "mailer"

  # Set default URL options for email links
  def default_url_options
    {
      host: Rails.application.config.action_mailer.default_url_options[:host] || "localhost:3000",
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol] || "http"
    }
  end
end
