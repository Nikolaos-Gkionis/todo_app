namespace :email do
  desc "Debug email sending step by step"
  task debug: :environment do
    puts "🔍 Debugging email functionality..."
    
    # Create a test user if one doesn't exist
    test_user = User.find_or_create_by(email_address: "test@example.com") do |user|
      user.name = "Test User"
      user.password = "password123"
      user.password_confirmation = "password123"
      user.start_trial!
    end
    
    puts "✅ Created/found test user: #{test_user.email_address}"
    puts "   Trial started: #{test_user.trial_started_at}"
    puts "   Trial expires: #{test_user.trial_expires_at}"
    puts "   Days remaining: #{test_user.trial_days_remaining}"
    
    # Test each email individually with error handling
    emails_to_test = [
      { name: "Purchase Confirmation", method: :purchase_confirmation, args: [test_user, "https://todo-it.app/download?token=test-123"] },
      { name: "Password Changed", method: :password_changed, args: [test_user] },
      { name: "Email Changed", method: :email_changed, args: [test_user, "old@example.com"] },
      { name: "Welcome Trial", method: :welcome_trial, args: [test_user] },
      { name: "Trial Expiring Soon", method: :trial_expiring_soon, args: [test_user] },
      { name: "Trial Expiring Very Soon", method: :trial_expiring_very_soon, args: [test_user] },
      { name: "Trial Expiring Tomorrow", method: :trial_expiring_tomorrow, args: [test_user] },
      { name: "Account Deleted", method: :account_deleted, args: [test_user.email_address] }
    ]
    
    emails_to_test.each_with_index do |email_test, index|
      begin
        puts "\n📧 Testing #{index + 1}/8: #{email_test[:name]}"
        UserMailer.send(email_test[:method], *email_test[:args]).deliver_now
        puts "   ✅ #{email_test[:name]} sent successfully"
      rescue => e
        puts "   ❌ #{email_test[:name]} failed: #{e.message}"
        puts "   📍 Error location: #{e.backtrace.first}"
      end
    end
    
    puts "\n🎉 Email debugging complete!"
    puts "Check MailCatcher at http://localhost:1080 to see the results."
  end
end
