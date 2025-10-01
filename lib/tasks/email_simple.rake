namespace :email do
  desc "Send a simple test email"
  task simple: :environment do
    puts "📧 Sending simple test email..."

    # Create a test user if one doesn't exist
    test_user = User.find_or_create_by(email_address: "test@example.com") do |user|
      user.name = "Test User"
      user.password = "password123"
      user.password_confirmation = "password123"
      user.start_trial!
    end

    puts "✅ User: #{test_user.email_address}"
    puts "📤 Sending welcome email..."

    begin
      UserMailer.welcome_trial(test_user).deliver_now
      puts "✅ Email sent successfully!"
      puts "🌐 Check MailCatcher at http://localhost:1080"
    rescue => e
      puts "❌ Email failed: #{e.message}"
      puts "💡 Make sure MailCatcher is running: mailcatcher"
    end
  end
end
