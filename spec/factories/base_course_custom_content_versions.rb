FactoryBot.define do
  factory :base_course_custom_content_version do
    # This parent factory's associations intentionally left blank.
    # Pass in base_course and custom_content_version to use it directly.

    sequence(:canvas_assignment_id)

    factory :course_project_version do
      association :base_course, factory: :course
      association :custom_content_version, factory: :project_version
    end

    factory :course_template_project_version do
      association :base_course, factory: :course_template
      association :custom_content_version, factory: :project_version
    end
  end
end
