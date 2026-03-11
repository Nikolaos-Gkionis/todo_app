namespace :email do
  desc "Test all emails and save them as separate files"
  task test_fixed: :environment do
    puts "📧 Testing all email types..."

    # Create a test user if one doesn't exist
    test_user = User.find_or_create_by(email_address: "test@example.com") do |user|
      user.name = "Test User"
      user.password = "password123"
      user.password_confirmation = "password123"
      user.start_trial!
    end

    puts "✅ User: #{test_user.email_address}"

    # Create output directory
    output_dir = Rails.root.join("tmp", "email_test")
    FileUtils.mkdir_p(output_dir)

    # Test each email type
    emails_to_test = [
      { name: "purchase_confirmation", method: :purchase_confirmation, args: [ test_user, "https://task-days.com/download?token=test-123" ] },
      { name: "password_changed", method: :password_changed, args: [ test_user ] },
      { name: "email_changed", method: :email_changed, args: [ test_user, "old@example.com" ] },
      { name: "welcome_trial", method: :welcome_trial, args: [ test_user ] },
      { name: "trial_expiring_soon", method: :trial_expiring_soon, args: [ test_user ] },
      { name: "trial_expiring_very_soon", method: :trial_expiring_very_soon, args: [ test_user ] },
      { name: "trial_expiring_tomorrow", method: :trial_expiring_tomorrow, args: [ test_user ] },
      { name: "account_deleted", method: :account_deleted, args: [ test_user.email_address ] }
    ]

    emails_to_test.each_with_index do |email_test, index|
      begin
        puts "📧 #{index + 1}/8: #{email_test[:name]}"

        # Generate the email
        email = UserMailer.send(email_test[:method], *email_test[:args])

        # Save as HTML file
        html_file = output_dir.join("#{email_test[:name]}.html")
        File.write(html_file, email.body.to_s)

        puts "   ✅ Saved to #{html_file}"
      rescue => e
        puts "   ❌ Failed: #{e.message}"
      end
    end

    puts "\n🎉 All emails generated successfully!"
    puts "📁 Check the files in: #{output_dir}"
    puts "🌐 Open them in your browser to see how they look"
    puts "\n📋 Files created:"
    system("ls -la #{output_dir}")
  end
end
