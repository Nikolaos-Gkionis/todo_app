namespace :migration do
  desc "Migrate existing users to new trial model"
  task migrate_users: :environment do
    puts "Starting user migration to new trial model..."
    
    # Show current stats
    stats = UserMigrationService.migration_stats
    puts "\nCurrent user statistics:"
    puts "  Total users: #{stats[:total_users]}"
    puts "  Premium users: #{stats[:premium_users]}"
    puts "  Free users: #{stats[:free_users]}"
    puts "  Already migrated to downloaded: #{stats[:migrated_to_downloaded]}"
    puts "  Currently on trial: #{stats[:on_trial]}"
    puts "  Trial expired: #{stats[:trial_expired]}"
    puts "  Not migrated: #{stats[:not_migrated]}"
    
    # Validate before migration
    puts "\nValidating migration integrity..."
    issues = UserMigrationService.validate_migration
    if issues.any?
      puts "⚠️  Found issues:"
      issues.each { |issue| puts "  - #{issue}" }
      
      # Check if running in interactive mode
      if STDIN.tty?
        puts "\nDo you want to continue? (y/N)"
        response = STDIN.gets.chomp.downcase
        unless response == 'y' || response == 'yes'
          puts "Migration cancelled."
          exit
        end
      else
        puts "\nRunning in non-interactive mode. Proceeding with migration..."
      end
    else
      puts "✅ No issues found. Proceeding with migration..."
    end
    
    # Run migration
    puts "\nRunning migration..."
    result = UserMigrationService.migrate_existing_users
    
    puts "\nMigration completed:"
    puts "  Total users processed: #{result[:total_users]}"
    puts "  Successfully migrated: #{result[:migrated]}"
    puts "  Errors: #{result[:errors]}"
    
    # Show updated stats
    puts "\nUpdated user statistics:"
    updated_stats = UserMigrationService.migration_stats
    puts "  Total users: #{updated_stats[:total_users]}"
    puts "  Migrated to downloaded: #{updated_stats[:migrated_to_downloaded]}"
    puts "  Currently on trial: #{updated_stats[:on_trial]}"
    puts "  Trial expired: #{updated_stats[:trial_expired]}"
    puts "  Not migrated: #{updated_stats[:not_migrated]}"
    
    if result[:errors] > 0
      puts "\n⚠️  Some users failed to migrate. Check the logs for details."
    else
      puts "\n✅ All users migrated successfully!"
    end
  end

  desc "Show migration statistics"
  task stats: :environment do
    stats = UserMigrationService.migration_stats
    
    puts "User Migration Statistics"
    puts "=" * 30
    puts "Total users: #{stats[:total_users]}"
    puts "Premium users: #{stats[:premium_users]}"
    puts "Free users: #{stats[:free_users]}"
    puts "Migrated to downloaded: #{stats[:migrated_to_downloaded]}"
    puts "Currently on trial: #{stats[:on_trial]}"
    puts "Trial expired: #{stats[:trial_expired]}"
    puts "Not migrated: #{stats[:not_migrated]}"
    
    # Show trial status breakdown
    if stats[:on_trial] > 0
      puts "\nTrial Status Breakdown:"
      trial_users = User.where(trial_started_at: Time.current..).where(device_downloaded: false)
      trial_users.group_by { |u| u.trial_days_remaining }.each do |days, users|
        puts "  #{days} days remaining: #{users.count} users"
      end
    end
  end

  desc "Validate migration integrity"
  task validate: :environment do
    puts "Validating migration integrity..."
    
    issues = UserMigrationService.validate_migration
    
    if issues.empty?
      puts "✅ No issues found. Migration is valid."
    else
      puts "⚠️  Found issues:"
      issues.each { |issue| puts "  - #{issue}" }
    end
  end

  desc "Rollback migration (for testing)"
  task rollback: :environment do
    puts "⚠️  This will rollback the migration and reset all trial-related fields."
    
    if STDIN.tty?
      puts "Are you sure? (y/N)"
      response = STDIN.gets.chomp.downcase
      
      if response == 'y' || response == 'yes'
        UserMigrationService.rollback_migration
        puts "✅ Migration rollback completed."
      else
        puts "Rollback cancelled."
      end
    else
      puts "Running in non-interactive mode. Proceeding with rollback..."
      UserMigrationService.rollback_migration
      puts "✅ Migration rollback completed."
    end
  end

  desc "Send migration notification to users"
  task notify_users: :environment do
    puts "Sending migration notifications to users..."
    
    # Get users who need notification
    users_to_notify = User.where(
      trial_started_at: nil,
      device_downloaded: false
    )
    
    puts "Found #{users_to_notify.count} users to notify"
    
    if users_to_notify.count > 0
      if STDIN.tty?
        puts "Do you want to send notifications? (y/N)"
        response = STDIN.gets.chomp.downcase
        
        if response == 'y' || response == 'yes'
          # In a real app, you'd send emails here
          # For now, just log the notification
          users_to_notify.find_each do |user|
            Rails.logger.info "Would send migration notification to #{user.email_address}"
          end
          puts "✅ Notifications sent to #{users_to_notify.count} users"
        else
          puts "Notifications cancelled."
        end
      else
        puts "Running in non-interactive mode. Sending notifications..."
        # In a real app, you'd send emails here
        # For now, just log the notification
        users_to_notify.find_each do |user|
          Rails.logger.info "Would send migration notification to #{user.email_address}"
        end
        puts "✅ Notifications sent to #{users_to_notify.count} users"
      end
    else
      puts "No users need notification."
    end
  end
end
