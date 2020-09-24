FactoryBot.define do
  factory :course_template do
    sequence(:name) { |i| "CourseTemplate #{i}" }
    type { "CourseTemplate" }
  end
end
