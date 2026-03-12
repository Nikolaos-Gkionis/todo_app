# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  # From address - must be verified in SendGrid (Single Sender Verification)
  # CONTACT_EMAIL is used as both sender and recipient for contact form
  default from: -> {
    email = ENV["CONTACT_EMAIL"].presence
    email ? "Peponi.to Contact <#{email}>" : "noreply@peponi.to"
  }

  # Send contact form submission to your email
  def contact_form(params)
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    @recipient = ENV["CONTACT_EMAIL"].presence || "support@peponi.to"

    subject = @message.present? ? @message.truncate(50) : "Contact from Peponi.to"
    subject = "Contact from Peponi.to: #{subject}" unless subject.start_with?("Contact from Peponi.to")

    mail(
      to: @recipient,
      subject: subject
    )
  end
end
