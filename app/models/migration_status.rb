class MigrationStatus < ApplicationRecord
  # Track migration progress and status
  
  validates :migration_type, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending running completed failed] }
  
  # Migration types
  MIGRATION_TYPES = %w[user_migration data_cleanup trial_cleanup].freeze
  
  # Status values
  STATUSES = %w[pending running completed failed].freeze
  
  # Get current migration status
  def self.current_status(migration_type)
    find_by(migration_type: migration_type)
  end
  
  # Start a migration
  def self.start_migration(migration_type, metadata = {})
    status = find_or_initialize_by(migration_type: migration_type)
    status.update!(
      status: 'running',
      started_at: Time.current,
      metadata: metadata
    )
    status
  end
  
  # Complete a migration
  def self.complete_migration(migration_type, results = {})
    status = find_by(migration_type: migration_type)
    return unless status
    
    status.update!(
      status: 'completed',
      completed_at: Time.current,
      results: results
    )
    status
  end
  
  # Fail a migration
  def self.fail_migration(migration_type, error_message)
    status = find_by(migration_type: migration_type)
    return unless status
    
    status.update!(
      status: 'failed',
      completed_at: Time.current,
      error_message: error_message
    )
    status
  end
  
  # Check if migration is running
  def running?
    status == 'running'
  end
  
  # Check if migration is completed
  def completed?
    status == 'completed'
  end
  
  # Check if migration failed
  def failed?
    status == 'failed'
  end
  
  # Get duration of migration
  def duration
    return nil unless started_at
    
    end_time = completed_at || Time.current
    end_time - started_at
  end
  
  # Get formatted duration
  def formatted_duration
    return 'N/A' unless duration
    
    if duration < 1.minute
      "#{(duration * 1000).round}ms"
    elsif duration < 1.hour
      "#{(duration / 1.minute).round}m #{(duration % 1.minute).round}s"
    else
      "#{(duration / 1.hour).round}h #{(duration % 1.hour / 1.minute).round}m"
    end
  end
end
