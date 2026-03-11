# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  # From address - must be verified in SendGrid (Single Sender Verification)
  # CONTACT_EMAIL is used as both sender and recipient for contact form
  default from: -> {
    email = ENV["CONTACT_EMAIL"].presence
    email ? "Task Days Contact <#{email}>" : "noreply@task-days.com"
  }

  # Send contact form submission to your email
  def contact_form(params)
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    @recipient = ENV["CONTACT_EMAIL"].presence || "support@task-days.com"

    subject = @message.present? ? @message.truncate(50) : "Contact from Task Days"
    subject = "Contact from Task Days: #{subject}" unless subject.start_with?("Contact from Task Days")

    mail(
      to: @recipient,
      subject: subject
    )
  end
end
