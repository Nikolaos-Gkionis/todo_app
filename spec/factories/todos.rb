FactoryBot.define do
  factory :todo do
    sequence(:title) { |n| "Todo #{n}" }
    completed { false }
    position { 1 }
    user { page&.user || association(:user) }
    page

    trait :completed do
      completed { true }
    end

    trait :dated do
      page { nil }
      due_date { Date.current }
    end
  end
end
