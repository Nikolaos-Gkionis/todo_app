namespace :email do
  desc "Preview email content by saving to files"
  task preview: :environment do
    puts "📧 Previewing email content..."
    
    # Create a test user if one doesn't exist
    test_user = User.find_or_create_by(email_address: "test@example.com") do |user|
      user.name = "Test User"
      user.password = "password123"
      user.password_confirmation = "password123"
      user.start_trial!
    end
    
    puts "✅ Created/found test user: #{test_user.email_address}"
    
    # Create preview directory
    preview_dir = Rails.root.join("tmp", "email_previews")
    FileUtils.mkdir_p(preview_dir)
    
    # Test each email and save to file
    emails_to_test = [
      { name: "purchase_confirmation", method: :purchase_confirmation, args: [test_user, "https://todo-it.app/download?token=test-123"] },
      { name: "password_changed", method: :password_changed, args: [test_user] },
      { name: "email_changed", method: :email_changed, args: [test_user, "old@example.com"] },
      { name: "welcome_trial", method: :welcome_trial, args: [test_user] },
      { name: "trial_expiring_soon", method: :trial_expiring_soon, args: [test_user] },
      { name: "trial_expiring_very_soon", method: :trial_expiring_very_soon, args: [test_user] },
      { name: "trial_expiring_tomorrow", method: :trial_expiring_tomorrow, args: [test_user] },
      { name: "account_deleted", method: :account_deleted, args: [test_user.email_address] }
    ]
    
    emails_to_test.each_with_index do |email_test, index|
      begin
        puts "📧 Generating #{index + 1}/8: #{email_test[:name]}"
        
        # Generate the email
        email = UserMailer.send(email_test[:method], *email_test[:args])
        
        # Save HTML content
        html_file = preview_dir.join("#{email_test[:name]}.html")
        File.write(html_file, email.body.to_s)
        
        # Save text content if available
        if email.text_part
          text_file = preview_dir.join("#{email_test[:name]}.txt")
          File.write(text_file, email.text_part.body.to_s)
        end
        
        puts "   ✅ #{email_test[:name]} saved to #{html_file}"
      rescue => e
        puts "   ❌ #{email_test[:name]} failed: #{e.message}"
        puts "   📍 Error: #{e.backtrace.first}"
      end
    end
    
    puts "\n🎉 Email previews generated!"
    puts "📁 Check the files in: #{preview_dir}"
    puts "🌐 Open them in your browser to see how they look"
  end
end
