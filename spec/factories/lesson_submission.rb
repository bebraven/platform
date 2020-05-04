FactoryBot.define do
  factory :lesson_submission do
    user { build(:registered_user) }
    lesson
  end
end

