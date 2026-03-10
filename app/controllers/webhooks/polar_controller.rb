# frozen_string_literal: true

module Webhooks
  class PolarController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_login
    skip_before_action :check_trial_status
    before_action :read_and_verify_webhook

    def create
      event = JSON.parse(@webhook_payload)
      event_type = event["type"]
      # Polar sends { type: "order.paid", data: { id, status, metadata, customer, ... } }
      data = event["data"] || event.dig("data", "data") || event

      case event_type
      when "order.paid", "order.updated"
        handle_order_paid(data) if data["status"] == "paid"
      when "order.created"
        # order.created can have status "pending" - wait for order.paid
        handle_order_paid(data) if data["status"] == "paid"
      else
        Rails.logger.info "Polar webhook: unhandled event type #{event_type}"
      end

      head :accepted
    end

    private

    def handle_order_paid(order_data)
      # Find user by metadata.user_id (from checkout) or customer email
      user = find_user_from_order(order_data)
      return unless user

      # Idempotent: skip if already processed
      return if user.device_downloaded?

      user.mark_as_downloaded!
      download_token = user.generate_download_token!

      # Store Polar order ID for reference
      user.update_column(:polar_order_id, order_data["id"]) if user.respond_to?(:polar_order_id)

      AnalyticsService.track_trial_conversion(user)
      AnalyticsService.track_payment_completion(user, order_data["id"])

      # Send download page URL (with token) so user lands on instructions page first.
      # Token allows access from email on another device without being logged in.
      download_page_url = download_url(token: download_token)
      install_guide_url = install_pwa_url(token: download_token)
      UserMailer.purchase_confirmation(user, download_page_url, install_guide_url).deliver_later

      Rails.logger.info "Polar order.paid: fulfilled for user #{user.id}"
    rescue StandardError => e
      Rails.logger.error "Polar webhook order.paid error: #{e.class} - #{e.message}"
      raise
    end

    def find_user_from_order(order_data)
      # Check metadata from checkout (we pass user_id)
      metadata = order_data["metadata"] || order_data["custom_field_data"] || {}
      user_id = metadata["user_id"]
      user = User.find_by(id: user_id) if user_id.present?
      return user if user

      # Fallback: find by customer email
      email = order_data.dig("customer", "email") || order_data["email"]
      return nil if email.blank?

      User.find_by("LOWER(email_address) = ?", email.downcase)
    end

    def read_and_verify_webhook
      @webhook_payload = request.raw_post
      return head(:bad_request) if @webhook_payload.blank?

      secret = ENV["POLAR_WEBHOOK_SECRET"] || Rails.application.credentials.dig(:polar, :webhook_secret)
      if secret.blank?
        Rails.logger.error "POLAR_WEBHOOK_SECRET is not set"
        head :forbidden
        return
      end

      payload = @webhook_payload
      # Standard Webhooks / Svix-style headers
      id = request.headers["Webhook-Id"] || request.headers["Svix-Id"]
      timestamp = request.headers["Webhook-Timestamp"] || request.headers["Svix-Timestamp"]
      signature = request.headers["Webhook-Signature"] || request.headers["Svix-Signature"]

      if id.blank? || timestamp.blank? || signature.blank?
        Rails.logger.warn "Polar webhook: missing signature headers"
        head :forbidden
        return
      end

      # Replay protection: reject if timestamp is too old (5 minutes)
      begin
        ts = Integer(timestamp)
        return head(:forbidden) if (Time.now.to_i - ts).abs > 300
      rescue ArgumentError
        return head(:forbidden)
      end

      # Standard Webhooks: HMAC-SHA256(id.timestamp.payload, secret) as hex
      # Polar doc: secret may need to be base64-decoded before use
      signed_payload = "#{id}.#{timestamp}.#{payload}"
      signing_secret = begin
        Base64.strict_decode64(secret)
      rescue ArgumentError
        secret
      end
      expected_hex = OpenSSL::HMAC.hexdigest("SHA256", signing_secret, signed_payload)

      # Signature format: "v1,hexsignature" (Standard Webhooks / Svix)
      sig_v1 = signature.include?(",") ? signature.split(",", 2).last.to_s.strip : nil
      valid = sig_v1.present? && ActiveSupport::SecurityUtils.secure_compare(sig_v1, expected_hex)

      unless valid
        # Try raw secret (no base64 decode)
        expected_hex_raw = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        valid = sig_v1.present? && ActiveSupport::SecurityUtils.secure_compare(sig_v1, expected_hex_raw)
      end

      head :forbidden unless valid
    end
  end
end
