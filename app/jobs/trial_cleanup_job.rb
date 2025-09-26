class TrialCleanupJob < ApplicationJob
  queue_as :default

  # Run daily to clean up expired trial data
  def perform
    Rails.logger.info "Starting trial cleanup job"

    cleanup_expired_trials
    cleanup_old_download_tokens
    cleanup_exported_data

    Rails.logger.info "Trial cleanup job completed"
  end

  private

  # Clean up users with expired trials who haven't downloaded
  def cleanup_expired_trials
    expired_users = User.where(
      trial_expires_at: ..Time.current,
      device_downloaded: false
    )

    Rails.logger.info "Found #{expired_users.count} users with expired trials"

    expired_users.find_each do |user|
      # Archive their data before cleanup
      archive_user_data(user)

      # Mark trial as expired (don't delete user account)
      user.update!(
        trial_data_exported: true, # Mark as exported so they can't re-export
        download_token: nil # Clear any download tokens
      )

      Rails.logger.info "Cleaned up expired trial for user #{user.id}"
    end
  end

  # Clean up old download tokens (older than 7 days)
  def cleanup_old_download_tokens
    old_tokens = User.where(
      download_token: User.where.not(download_token: nil)
                          .where(updated_at: ..7.days.ago)
                          .select(:download_token)
    )

    Rails.logger.info "Found #{old_tokens.count} users with old download tokens"

    old_tokens.update_all(download_token: nil)

    Rails.logger.info "Cleaned up #{old_tokens.count} old download tokens"
  end

  # Clean up exported data for users who have downloaded
  def cleanup_exported_data
    # For users who have successfully downloaded, we can clean up some data
    # but keep their account and basic info
    downloaded_users = User.where(device_downloaded: true)

    Rails.logger.info "Found #{downloaded_users.count} users with downloaded apps"

    # In a real app, you might want to:
    # - Archive their trial data
    # - Clean up old logs
    # - Optimize their data structure
    # For now, we'll just log this
    Rails.logger.info "Downloaded users data cleanup completed"
  end

  # Archive user data before cleanup
  def archive_user_data(user)
    return unless user.pages.any?

    begin
      # Create a backup of their data
      backup_data = {
        user_id: user.id,
        email: user.email_address,
        name: user.name,
        trial_started_at: user.trial_started_at,
        trial_expires_at: user.trial_expires_at,
        pages: user.pages.map do |page|
          {
            name: page.name,
            description: page.description,
            cover_color: page.cover_color,
            created_at: page.created_at,
            todos: page.todos.map do |todo|
              {
                title: todo.title,
                notes: todo.notes,
                completed: todo.completed,
                position: todo.position,
                due_date: todo.due_date,
                created_at: todo.created_at
              }
            end
          }
        end,
        archived_at: Time.current
      }

      # In a real app, you'd save this to a backup storage
      # For now, we'll just log it
      Rails.logger.info "Archived data for user #{user.id}: #{backup_data.to_json}"

    rescue => e
      Rails.logger.error "Failed to archive data for user #{user.id}: #{e.message}"
    end
  end
end
