class User < ApplicationRecord
    include TrialManageable

    has_many :pages, dependent: :destroy
    has_many :todos, dependent: :destroy

    # Enable secure password functionality
    has_secure_password

    validates :email_address, presence: true, uniqueness: true
    validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :name, presence: true, length: { minimum: 2, maximum: 50 }, on: :create
    validates :name, length: { minimum: 2, maximum: 50 }, allow_blank: true, on: :update
    validates :password, length: { minimum: 6 }, on: :create
    validates :font_family, inclusion: { in: %w[default serif sans_serif handwritten system_ui georgia menlo] }, allow_blank: true
    validates :app_title, length: { minimum: 1, maximum: 30 }, allow_nil: false
    validates :not_yet_panel_title, length: { minimum: 1, maximum: 50 }, allow_blank: false, if: -> { self.class.column_names.include?("not_yet_panel_title") }
    validates :lists_placement, inclusion: { in: %w[bottom right] }, allow_blank: true, if: -> { self.class.column_names.include?("lists_placement") }

    def increment_download_count!
      increment!(:download_count)
    end

    # Remember token functionality for persistent authentication
    def remember_me!
      # Generate a secure random token
      self.remember_token = SecureRandom.urlsafe_base64
      # Set expiration to 1 year from now (like YouTube, etc.)
      self.remember_token_expires_at = 1.year.from_now
      save!
    end

    def forget_me!
      self.remember_token = nil
      self.remember_token_expires_at = nil
      save!
    end

    def remember_token_valid?
      remember_token.present? &&
      remember_token_expires_at.present? &&
      remember_token_expires_at > Time.current
    end

    def remember_token_expires_soon?
      remember_token_expires_at.present? &&
      remember_token_expires_at <= 30.days.from_now &&
      remember_token_expires_at > Time.current
    end

    def refresh_remember_token!
      return unless remember_token_valid?
      # Extend the token by another year when user is active
      self.remember_token_expires_at = 1.year.from_now
      save!
    end

    # Display name for the user (name if available, otherwise email)
    def display_name
      name.presence || email_address
    end

    # Desktop helper API (Omarchy / peponi CLI) — store digest only; raw token returned once.
    DESKTOP_API_TOKEN_TTL = 1.year

    def issue_desktop_api_token!
      raw = SecureRandom.urlsafe_base64(32)
      update!(
        desktop_api_token_digest: self.class.digest_desktop_api_token(raw),
        desktop_api_token_expires_at: DESKTOP_API_TOKEN_TTL.from_now
      )
      raw
    end

    def revoke_desktop_api_token!
      update!(desktop_api_token_digest: nil, desktop_api_token_expires_at: nil)
    end

    def desktop_api_token_valid?(raw)
      return false if raw.blank? || desktop_api_token_digest.blank?
      return false if desktop_api_token_expires_at.blank? || desktop_api_token_expires_at <= Time.current

      ActiveSupport::SecurityUtils.secure_compare(
        desktop_api_token_digest,
        self.class.digest_desktop_api_token(raw)
      )
    end

    def self.digest_desktop_api_token(raw)
      Digest::SHA256.hexdigest(raw.to_s)
    end

    def self.find_by_desktop_api_token(raw)
      return nil if raw.blank?

      user = find_by(desktop_api_token_digest: digest_desktop_api_token(raw))
      return nil unless user&.desktop_api_token_valid?(raw)

      user
    end
end
