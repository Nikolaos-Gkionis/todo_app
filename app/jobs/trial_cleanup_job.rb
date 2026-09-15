class TrialCleanupJob < ApplicationJob
  queue_as :default

  # On peponi.to, delete hosted accounts whose week is over.
  # Self-hosted clones never set HOSTED_EPHEMERAL, so this is a no-op there.
  def perform
    unless User.hosted_ephemeral?
      Rails.logger.info "TrialCleanupJob skipped (HOSTED_EPHEMERAL is off)"
      return
    end

    expired_users = User.where(trial_expires_at: ..Time.current)

    expired_users.find_each do |user|
      if user.grandfathered_purchaser?
        Rails.logger.info "Skipping grandfathered purchaser #{user.id}"
        next
      end

      user.destroy
      Rails.logger.info "Deleted expired hosted account #{user.id}"
    end
  end
end
