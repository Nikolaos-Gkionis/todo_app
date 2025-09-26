class UserMigrationService
  # Migrate existing users to the new trial model
  def self.migrate_existing_users
    Rails.logger.info "Starting user migration to new trial model"

    # Start migration tracking
    migration_status = MigrationStatus.start_migration("user_migration", {
      started_by: "system",
      environment: Rails.env
    })

    begin
      # Get all existing users who haven't been migrated yet
      users_to_migrate = User.where(
        trial_started_at: nil,
        device_downloaded: false
      )

      Rails.logger.info "Found #{users_to_migrate.count} users to migrate"

      migrated_count = 0
      error_count = 0

      users_to_migrate.find_each do |user|
        begin
          migrate_user(user)
          migrated_count += 1
          Rails.logger.info "Migrated user #{user.id} (#{user.email_address})"
        rescue => e
          error_count += 1
          Rails.logger.error "Failed to migrate user #{user.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end

      results = {
        total_users: users_to_migrate.count,
        migrated: migrated_count,
        errors: error_count
      }

      # Complete migration tracking
      MigrationStatus.complete_migration("user_migration", results)

      Rails.logger.info "Migration completed: #{migrated_count} migrated, #{error_count} errors"

      results

    rescue => e
      # Fail migration tracking
      MigrationStatus.fail_migration("user_migration", e.message)
      Rails.logger.error "Migration failed: #{e.message}"
      raise
    end
  end

  # Migrate a single user
  def self.migrate_user(user)
    # Determine migration strategy based on user's current status
    if user.premium?
      # Premium users get immediate access (grandfathered)
      migrate_premium_user(user)
    else
      # Free users get a 30-day trial
      migrate_free_user(user)
    end
  end

  private

  # Migrate premium users - they get immediate access to downloaded app
  def self.migrate_premium_user(user)
    Rails.logger.info "Migrating premium user #{user.id} to downloaded app status"

    user.update!(
      device_downloaded: true,
      trial_started_at: user.created_at, # Use account creation as trial start
      trial_expires_at: user.created_at + 30.days, # 30 days from account creation
      download_token: SecureRandom.urlsafe_base64(32)
    )

    # Track this as a special migration
    Rails.logger.info "Premium user #{user.id} migrated to downloaded app status"
  end

  # Migrate free users - they get a 30-day trial
  def self.migrate_free_user(user)
    Rails.logger.info "Migrating free user #{user.id} to trial status"

    # Give them a 30-day trial starting now
    now = Time.current
    user.update!(
      trial_started_at: now,
      trial_expires_at: now + 30.days
    )

    Rails.logger.info "Free user #{user.id} migrated to trial status"
  end

  # Get migration statistics
  def self.migration_stats
    {
      total_users: User.count,
      premium_users: User.where(premium: true).count,
      free_users: User.where(premium: false).count,
      migrated_to_downloaded: User.where(device_downloaded: true).count,
      on_trial: User.where(trial_started_at: Time.current..).where(device_downloaded: false).count,
      trial_expired: User.where(trial_expires_at: ..Time.current).where(device_downloaded: false).count,
      not_migrated: User.where(trial_started_at: nil, device_downloaded: false).count
    }
  end

  # Validate migration integrity
  def self.validate_migration
    issues = []

    # Check for users with invalid trial dates
    invalid_trial_users = User.where(
      "trial_started_at IS NOT NULL AND trial_expires_at IS NOT NULL AND trial_expires_at <= trial_started_at"
    )

    if invalid_trial_users.any?
      issues << "Found #{invalid_trial_users.count} users with invalid trial dates"
    end

    # Check for users with both premium and device_downloaded false
    inconsistent_users = User.where(premium: true, device_downloaded: false)
    if inconsistent_users.any?
      issues << "Found #{inconsistent_users.count} premium users not marked as downloaded"
    end

    # Check for users with trial data but no trial dates
    orphaned_trial_data = User.where(trial_data_exported: true, trial_started_at: nil)
    if orphaned_trial_data.any?
      issues << "Found #{orphaned_trial_data.count} users with trial data but no trial dates"
    end

    issues
  end

  # Rollback migration (for testing)
  def self.rollback_migration
    Rails.logger.info "Rolling back user migration"

    # Reset all trial-related fields
    User.update_all(
      trial_started_at: nil,
      trial_expires_at: nil,
      device_downloaded: false,
      download_token: nil,
      trial_data_exported: false
    )

    Rails.logger.info "Migration rollback completed"
  end
end
