FactoryBot.define do
  factory :todo do
    sequence(:title) { |n| "Todo #{n}" }
    completed { false }
    position { 1 }
    page

    trait :completed do
      completed { true }
    end

    trait :with_due_date do
      due_date { 1.week.from_now }
    end

    trait :overdue do
      due_date { 1.day.ago }
    end

    trait :due_today do
      due_date { Date.current }
    end
  end
end
