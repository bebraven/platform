FactoryBot.define do
  factory :section do
    sequence(:name) { |i| "Section Name #{i}" }

    association :course, factory: :course
    association :logistic, factory: :logistic
  end
end
