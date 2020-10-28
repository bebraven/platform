FactoryBot.define do
  factory :project_submission do
    user { build :fellow_user, section: build(:section) }
    base_course_custom_content_version { build :course_project_version }
  end
end

