FactoryBot.define do
  factory :course_membership do
    user { build(:registered_user) }
    course
    role
  end
end
