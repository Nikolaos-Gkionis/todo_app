# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  # Use Gmail address as sender (must match SMTP auth user for Gmail)
  default from: -> { ENV["CONTACT_EMAIL"].presence || "noreply@todo-it.app" }

  # Send contact form submission to your email
  def contact_form(params)
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    @recipient = ENV["CONTACT_EMAIL"].presence || "support@todo-it.app"

    subject = @message.present? ? @message.truncate(50) : "Contact from Todo-it"
    subject = "Contact from Todo-it: #{subject}" unless subject.start_with?("Contact from Todo-it")

    mail(
      to: @recipient,
      subject: subject
    )
  end
end
