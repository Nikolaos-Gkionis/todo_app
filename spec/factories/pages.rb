FactoryBot.define do
  factory :page do
    sequence(:name) { |n| "Page #{n}" }
    user

    trait :with_todos do
      after(:create) do |page|
        create_list(:todo, 3, page: page)
      end
    end

    trait :with_many_todos do
      after(:create) do |page|
        create_list(:todo, 10, page: page)
      end
    end
  end
end
