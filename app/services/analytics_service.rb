class AnalyticsService
  # Track trial-to-download conversion
  def self.track_trial_conversion(user)
    Rails.logger.info "Trial conversion tracked for user #{user.id}"

    # In a real app, you'd send this to your analytics service
    # For now, we'll just log it
    conversion_data = {
      user_id: user.id,
      email: user.email_address,
      trial_started_at: user.trial_started_at,
      trial_expires_at: user.trial_expires_at,
      converted_at: Time.current,
      days_in_trial: user.trial_days_remaining,
      pages_created: user.pages.count,
      total_todos: user.pages.joins(:todos).count
    }

    Rails.logger.info "Conversion data: #{conversion_data.to_json}"

    # You could also send to external services like:
    # - Google Analytics
    # - Mixpanel
    # - Amplitude
    # - Custom analytics database
  end

  # Track download success
  def self.track_download_success(user, download_token)
    Rails.logger.info "Download success tracked for user #{user.id}"

    download_data = {
      user_id: user.id,
      email: user.email_address,
      download_token: download_token,
      downloaded_at: Time.current,
      trial_duration_days: user.trial_days_remaining,
      data_exported: user.pages.any?
    }

    Rails.logger.info "Download data: #{download_data.to_json}"
  end

  # Track payment completion
  def self.track_payment_completion(user, session_id)
    Rails.logger.info "Payment completion tracked for user #{user.id}"

    payment_data = {
      user_id: user.id,
      email: user.email_address,
      stripe_session_id: session_id,
      payment_completed_at: Time.current,
      amount: 990, # $9.99 in cents
      currency: "usd"
    }

    Rails.logger.info "Payment data: #{payment_data.to_json}"
  end

  # Track trial start
  def self.track_trial_start(user)
    Rails.logger.info "Trial start tracked for user #{user.id}"

    trial_data = {
      user_id: user.id,
      email: user.email_address,
      trial_started_at: Time.current,
      trial_expires_at: user.trial_expires_at
    }

    Rails.logger.info "Trial data: #{trial_data.to_json}"
  end
end
