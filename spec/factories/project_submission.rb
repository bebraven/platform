FactoryBot.define do
  factory :project_submission do
    user { build(:registered_user) }
    project
  end
end

