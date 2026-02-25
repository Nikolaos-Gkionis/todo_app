# frozen_string_literal: true

class ContactController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]
  skip_before_action :check_trial_status, only: [ :new, :create ]

  before_action :set_marketing_nav

  def new
    # Render contact form (no auth required)
  end

  def create
    # Honeypot: if "website" field is filled, treat as bot - pretend success
    if params[:website].present?
      redirect_to contact_path, notice: "Thanks! We'll get back to you."
      return
    end

    # Basic validation
    name = params[:name].to_s.strip
    email = params[:email].to_s.strip
    message = params[:message].to_s.strip

    if email.blank? || message.blank?
      flash.now[:alert] = "Please provide your email and message."
      render :new, status: :unprocessable_entity
      return
    end

    unless email.match?(/\A[^@\s]+@[^@\s]+\z/)
      flash.now[:alert] = "Please enter a valid email address."
      render :new, status: :unprocessable_entity
      return
    end

    # Send email
    begin
      ContactMailer.contact_form(name: name, email: email, message: message).deliver_now
      redirect_to contact_path, notice: "Thanks! We'll get back to you soon."
    rescue StandardError => e
      Rails.logger.error "Contact form delivery failed: #{e.message}"
      flash.now[:alert] = "Sorry, we couldn't send your message. Please try again later."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_marketing_nav
    @marketing_nav = true
  end
end
