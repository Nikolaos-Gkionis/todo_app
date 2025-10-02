FactoryBot.define do
  factory :todo do
    sequence(:title) { |n| "Todo #{n}" }
    completed { false }
    position { 1 }
    page

    trait :completed do
      completed { true }
    end
  end
end
