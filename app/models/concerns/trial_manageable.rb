module TrialManageable
  extend ActiveSupport::Concern

  included do
    HOSTED_DURATION_DAYS = 7
  end

  class_methods do
    # True only on peponi.to. Self-hosted clones leave this off so accounts last.
    def hosted_ephemeral?
      Rails.application.config.x.hosted_ephemeral
    end
  end

  def hosted_ephemeral?
    self.class.hosted_ephemeral?
  end

  # People who already paid keep their hosted account.
  def grandfathered_purchaser?
    (respond_to?(:paid_at) && paid_at.present?) || device_downloaded?
  end

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

  def premium?
    grandfathered_purchaser?
  end

  def free?
    !premium?
  end

  def on_trial?
    hosted_ephemeral? && trial_active? && !grandfathered_purchaser?
  end

  def downloaded_app?
    device_downloaded?
  end

  def needs_trial_start?
    return false unless hosted_ephemeral?
    return false if grandfathered_purchaser?

    !trial_started?
  end

  def can_create_page?
    can_use_app?
  end

  def remaining_pages
    can_use_app? ? "∞" : "0"
  end

  def can_use_premium_themes?
    true
  end

  # Self-host: always. Hosted week (or a past purchase): yes. After the hosted week: no.
  def can_use_app?
    return true unless hosted_ephemeral?
    return true if grandfathered_purchaser?

    trial_active?
  end

  def can_install_pwa?
    can_use_app?
  end

  def start_trial!
    return false unless hosted_ephemeral?
    return false if trial_started? || grandfathered_purchaser?

    now = Time.current
    update!(
      trial_started_at: now,
      trial_expires_at: now + HOSTED_DURATION_DAYS.days
    )
    true
  end

  def generate_download_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(download_token: token)
    token
  end

  def mark_as_downloaded!
    update!(device_downloaded: true, download_token: nil)
  end

  def trial_days_remaining
    return 0 unless trial_active?

    (trial_expires_at - Time.current).to_i / 1.day
  end

  def trial_expires_in_days
    trial_days_remaining
  end

  def trial_warning_days
    [ 3, 1 ]
  end

  def should_show_trial_warning?
    return false unless on_trial?

    trial_warning_days.include?(trial_days_remaining)
  end
end
