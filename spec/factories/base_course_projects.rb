FactoryBot.define do
  factory :base_course_project do
    project

    factory :course_project do
      association :base_course, factory: :course
    end

    factory :course_template_project do
      association :base_course, factory: :course_template
    end
  end
end
