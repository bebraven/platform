FactoryBot.define do
  factory :lesson_interaction do
    user { build(:registered_user) }
    activity_id { "MyString" }
    canvas_course_id { 10 }
    canvas_assignment_id { 20 }

    factory :progressed_lesson_interaction do
      verb { LessonInteraction::PROGRESSED }
      progress { 0 }
    end

    factory :answered_lesson_interaction do
      verb { LessonInteraction::ANSWERED }
      success { true }
    end
  end
end
