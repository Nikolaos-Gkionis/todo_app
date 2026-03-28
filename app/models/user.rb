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

    # Download tracking
    MAX_DOWNLOADS = 3

    def can_download?
      (download_count || 0) < MAX_DOWNLOADS
    end

    def increment_download_count!
      increment!(:download_count)
    end

    def downloads_remaining
      MAX_DOWNLOADS - (download_count || 0)
    end

    # PWA install restriction: only paid users can install the app
    # Trial users keep full server access but cannot add the PWA to their device
    # Include device_downloaded for legacy purchasers who may not have paid_at
    def can_install_pwa?
      return true if device_downloaded?
      respond_to?(:paid_at) && paid_at.present?
    end

    # Entitlement to use the web app (trial in-browser only, or after purchase / legacy)
    def can_use_app?
      trial_active? || can_install_pwa?
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
end
