FactoryBot.define do
  factory :project_submission do
    user { build :fellow_user, section: build(:section) }
    project { build :project }
  end
end

