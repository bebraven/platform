FactoryBot.define do
  factory :project_submission do
    user { build :fellow_user }
    project { build :project }
  end
end

