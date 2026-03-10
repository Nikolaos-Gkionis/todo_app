# frozen_string_literal: true

# Polar::ProductManager - Creates products on Polar.sh for one-time digital downloads.
# Uses Rails.application.credentials.dig(:polar, :access_token) or ENV["POLAR_ACCESS_TOKEN"].
#
# Note: File upload for Polar downloadables requires multipart S3 - for Todo-it's
# dynamically generated PWA ZIP, we fulfill downloads via webhook (order.paid) and our
# own download endpoint. Product creation here sets up the one-time purchase product
# with UK VAT/tax offloaded to Polar.
module Polar
  class ProductManager
    class Error < StandardError; end

    BASE_URL = "https://api.polar.sh/v1"
    SANDBOX_URL = "https://sandbox-api.polar.sh/v1"

    def initialize(access_token: nil, sandbox: false)
      @access_token = access_token ||
        Rails.application.credentials.dig(:polar, :access_token) ||
        ENV["POLAR_ACCESS_TOKEN"]
      @base_url = sandbox ? SANDBOX_URL : BASE_URL
    end

    # Create a 100% discount for testing (gift code).
    # @param organization_id [String] Polar organization UUID (optional if using org token)
    # @return [Hash] Discount response with id
    def create_test_discount(organization_id: nil)
      raise Error, "Polar access token not configured" if @access_token.blank?

      body = {
        duration: "once",
        type: "percentage",
        basis_points: 10_000, # 100%
        name: "Todo-it Test 100%",
        code: "FAMTEST",
        organization_id: organization_id
      }.compact

      response = faraday_client.post("discounts/", body)
      unless response.success?
        raise Error, "Polar discount creation failed: #{response.status} #{response.body}"
      end

      data = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
      discount = data["discount"] || data
      { "id" => discount["id"] }.merge(discount)
    end

    # Create a one-time product for Todo-it Download (£9.99).
    # Requires ORGANIZATION_ID from your Polar dashboard.
    # @param organization_id [String] Polar organization UUID
    # @return [Hash] Product response with id
    def create_download_product(organization_id:)
      raise Error, "Polar access token not configured" if @access_token.blank?
      raise Error, "Organization ID required" if organization_id.blank?

      body = {
        name: "Todo-it - Download to Device",
        description: "Download to your device forever - unlimited pages, offline access, and data ownership",
        organization_id: organization_id,
        # One-time product (recurring_interval: null)
        recurring_interval: nil,
        prices: [
          {
            amount_type: "fixed",
            price_currency: "gbp",
            price_amount: 999 # £9.99 in pence
          }
        ]
      }

      response = faraday_client.post("products/", body)

      unless response.success?
        raise Error, "Polar product creation failed: #{response.status} #{response.body}"
      end

      response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
    end

    # Create a checkout session and return the checkout URL.
    # @param product_id [String] Polar product UUID
    # @param customer_email [String] Buyer email
    # @param success_url [String] URL to redirect after successful payment
    # @param return_url [String] Optional URL for checkout "back" button
    # @param discount_id [String] Optional discount UUID (100% for testing)
    # @param metadata [Hash] Custom data (e.g. user_id)
    # @return [String] Checkout URL to redirect user to
    def create_checkout(product_id:, customer_email:, success_url:, return_url: nil, discount_id: nil, metadata: {})
      raise Error, "Polar access token not configured" if @access_token.blank?

      body = {
        products: [ product_id ],
        customer_email: customer_email,
        success_url: success_url,
        return_url: return_url,
        discount_id: discount_id,
        metadata: metadata
      }.compact

      # Faraday: path without leading / to preserve base URL's /v1
      response = faraday_client.post("checkouts/", body)

      unless response.success?
        raise Error, "Polar checkout creation failed: #{response.status} #{response.body}"
      end

      data = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
      data["url"] || raise(Error, "No checkout URL in Polar response")
    end

    private

    def faraday_client
      @faraday_client ||= Faraday.new(url: @base_url) do |f|
        f.request :json
        f.response :json
        f.headers["Authorization"] = "Bearer #{@access_token}"
        f.headers["Content-Type"] = "application/json"
        f.headers["Accept"] = "application/json"
      end
    end
  end
end
