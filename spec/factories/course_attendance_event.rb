FactoryBot.define do
  factory :course_attendance_event do
    sequence(:canvas_assignment_id)
    association :course, factory: :course
    association :attendance_event, factory: :attendance_event

    factory :one_on_one_course_attendance_event do
      association :attendance_event, factory: :one_on_one_attendance_event
    end
  end
end