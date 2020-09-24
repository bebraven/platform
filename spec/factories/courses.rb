FactoryBot.define do
  factory :course do
    sequence(:name) { |i| "Course #{i}" }
    type { "Course" }

    factory :course_with_canvas_id do
      canvas_course_id { 55 }

      factory :course_with_resource do
        association :course_resource, factory: :course_resource_with_zipfile
      end
    end
  end
end
