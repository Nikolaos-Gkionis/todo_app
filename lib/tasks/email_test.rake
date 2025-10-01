namespace :email do
  desc "Test email sending functionality"
  task test: :environment do
    puts "Testing email functionality..."
    
    # Create a test user if one doesn't exist
    test_user = User.find_or_create_by(email_address: "test@example.com") do |user|
      user.name = "Test User"
      user.password = "password123"
      user.password_confirmation = "password123"
      user.start_trial!
    end
    
    puts "Created/found test user: #{test_user.email_address}"
    
    # Test purchase confirmation email
    puts "Sending purchase confirmation email..."
    download_url = "https://todo-it.app/download?token=test-token-123"
    UserMailer.purchase_confirmation(test_user, download_url).deliver_now
    puts "✅ Purchase confirmation email sent"
    
    # Test password change email
    puts "Sending password change email..."
    UserMailer.password_changed(test_user).deliver_now
    puts "✅ Password change email sent"
    
    # Test email change email
    puts "Sending email change email..."
    UserMailer.email_changed(test_user, "old@example.com").deliver_now
    puts "✅ Email change email sent"
    
    # Test welcome trial email
    puts "Sending welcome trial email..."
    UserMailer.welcome_trial(test_user).deliver_now
    puts "✅ Welcome trial email sent"
    
    # Test trial expiration emails
    puts "Sending trial expiration emails..."
    UserMailer.trial_expiring_soon(test_user).deliver_now
    puts "✅ Trial expiring soon email sent"
    
    UserMailer.trial_expiring_very_soon(test_user).deliver_now
    puts "✅ Trial expiring very soon email sent"
    
    UserMailer.trial_expiring_tomorrow(test_user).deliver_now
    puts "✅ Trial expiring tomorrow email sent"
    
    # Test account deletion email
    puts "Sending account deletion email..."
    UserMailer.account_deleted(test_user.email_address).deliver_now
    puts "✅ Account deletion email sent"
    
    puts "\n🎉 All test emails sent successfully!"
    puts "Check your email client or mailcatcher to view the emails."
  end
  
  desc "Test specific email type"
  task :test_type, [:type] => :environment do |t, args|
    type = args[:type]
    
    # Create a test user if one doesn't exist
    test_user = User.find_or_create_by(email_address: "test@example.com") do |user|
      user.name = "Test User"
      user.password = "password123"
      user.password_confirmation = "password123"
      user.start_trial!
    end
    
    case type
    when "purchase"
      download_url = "https://todo-it.app/download?token=test-token-123"
      UserMailer.purchase_confirmation(test_user, download_url).deliver_now
      puts "✅ Purchase confirmation email sent"
    when "password"
      UserMailer.password_changed(test_user).deliver_now
      puts "✅ Password change email sent"
    when "email"
      UserMailer.email_changed(test_user, "old@example.com").deliver_now
      puts "✅ Email change email sent"
    when "welcome"
      UserMailer.welcome_trial(test_user).deliver_now
      puts "✅ Welcome trial email sent"
    when "trial_soon"
      UserMailer.trial_expiring_soon(test_user).deliver_now
      puts "✅ Trial expiring soon email sent"
    when "trial_very_soon"
      UserMailer.trial_expiring_very_soon(test_user).deliver_now
      puts "✅ Trial expiring very soon email sent"
    when "trial_tomorrow"
      UserMailer.trial_expiring_tomorrow(test_user).deliver_now
      puts "✅ Trial expiring tomorrow email sent"
    when "deleted"
      UserMailer.account_deleted(test_user.email_address).deliver_now
      puts "✅ Account deletion email sent"
    else
      puts "❌ Unknown email type: #{type}"
      puts "Available types: purchase, password, email, welcome, trial_soon, trial_very_soon, trial_tomorrow, deleted"
    end
  end
end
