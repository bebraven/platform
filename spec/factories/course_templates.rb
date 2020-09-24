FactoryBot.define do
  factory :course_template do
    sequence(:name) { |i| "CourseTemplate #{i}" }
    type { "CourseTemplate" }

    factory :course_template_with_canvas_id do
      canvas_course_id { 55 }

      factory :course_template_with_resource do
        association :course_resource, factory: :course_resource_with_zipfile
      end
    end
  end
end
