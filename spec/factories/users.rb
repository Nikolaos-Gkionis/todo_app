FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    premium { false }
    device_downloaded { false }
    trial_started_at { nil }
    trial_expires_at { nil }
    download_token { nil }

    trait :with_trial do
      trial_started_at { 4.days.ago }
      trial_expires_at { 3.days.from_now }
    end

    trait :trial_expired do
      trial_started_at { 10.days.ago }
      trial_expires_at { 3.days.ago }
    end

    trait :downloaded_app do
      device_downloaded { true }
      download_token { nil }
    end

    trait :premium do
      premium { true }
      device_downloaded { true }
    end

    trait :with_download_token do
      download_token { SecureRandom.urlsafe_base64(32) }
    end
  end
end
