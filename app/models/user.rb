class User < ApplicationRecord
    has_many :pages, dependent: :destroy

    # Enable secure password functionality
    has_secure_password

    validates :email_address, presence: true, uniqueness: true
    validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :name, presence: true, length: { minimum: 2, maximum: 50 }, on: :create
    validates :name, length: { minimum: 2, maximum: 50 }, allow_blank: true, on: :update

    # Trial and download limits
    TRIAL_DURATION_DAYS = 30
    MAX_FREE_PAGES = 3
    MAX_FREE_TODOS_PER_PAGE = 20

    # Trial status helpers
    def trial_active?
      trial_started_at.present? && trial_expires_at.present? && trial_expires_at > Time.current
    end

    def trial_expired?
      trial_started_at.present? && trial_expires_at.present? && trial_expires_at <= Time.current
    end

    def trial_started?
      trial_started_at.present?
    end

    def device_downloaded?
      device_downloaded
    end

    # Legacy premium status (for backward compatibility)
    def premium?
      device_downloaded?
    end

    def free?
      !premium?
    end

    # New model status helpers
    def on_trial?
      trial_active? && !device_downloaded?
    end

    def downloaded_app?
      device_downloaded?
    end

    def needs_trial_start?
      !trial_started? && !device_downloaded?
    end

    # Check if user can create more pages
    def can_create_page?
      return true if downloaded_app?
      return true if on_trial?
      false # No access if trial expired and not downloaded
    end

    # Get remaining page slots for trial users
    def remaining_pages
      return "∞" if downloaded_app?
      return "∞" if on_trial?
      "0" # No access if trial expired and not downloaded
    end

    # Check if user can access themes (now available to everyone)
    def can_use_premium_themes?
      true # All themes available to everyone now
    end

    # Trial management methods
    def start_trial!
      return false if trial_started? || device_downloaded?

      now = Time.current
      update!(
        trial_started_at: now,
        trial_expires_at: now + TRIAL_DURATION_DAYS.days
      )
      true
    end

    def generate_download_token!
      token = SecureRandom.urlsafe_base64(32)
      update!(download_token: token)
      token
    end

    def mark_as_downloaded!
      update!(
        device_downloaded: true,
        download_token: nil # Clear token after successful download
      )
    end

    def trial_days_remaining
      return 0 unless trial_active?
      (trial_expires_at - Time.current).to_i / 1.day
    end

    def trial_expires_in_days
      return 0 unless trial_active?
      trial_days_remaining
    end

    def trial_warning_days
      [ 7, 3, 1 ] # Days before expiry to show warnings
    end

    def should_show_trial_warning?
      return false unless trial_active?
      trial_warning_days.include?(trial_days_remaining)
    end

    # Display name for the user (name if available, otherwise email)
    def display_name
      name.presence || email_address
    end
end
