FactoryBot.define do
  # Represents an AssignmentOverride returned from the canvas API
  # See: https://canvas.instructure.com/doc/api/assignments.html#method.assignments_api.index
  #
  # Important: this is meant to be built with FactoryBot.json(:canvas_assignment_override)
  factory :canvas_assignment_override, class: Hash do
    skip_create # This isn't stored in the DB.

    sequence(:id) 
    sequence(:assignment_id) 
    due_at { nil }
    all_day { false }
    all_day_date { nil }

    factory :canvas_assignment_override_due do
      # Arbitrary non-nil due date.
      due_at { 3.days.from_now.utc.to_time.iso8601 }

      factory :canvas_assignment_override_section do
        sequence(:title) { |i| "Test - Section#{i}" }
        # Despite its name, the course_section_id is a Canvas section_id.
        sequence(:course_section_id)
      end

      factory :canvas_assignment_override_user do
        sequence(:title) { |i| "Test - one student" }
        sequence(:student_ids) { [i] }
      end
    end

    initialize_with { attributes.stringify_keys }
  end
end

# Example (with section)
#{
#    "id": 208,
#    "assignment_id": 816,
#    "course_section_id": 226,
#    "title": "Monday, 6pm",
#    "due_at": "2021-03-13T05:59:59Z",
#    "all_day": false,
#    "all_day_date": nil,
#    "lock_at": nil,
#    "unlock_at": nil,
#}
# Example (with user)
#{
#    "id": 208,
#    "assignment_id": 816,
#    "student_ids": [1, 2, 3],
#    "title": "3 students",
#    "due_at": "2021-03-13T05:59:59Z",
#    "all_day": false,
#    "all_day_date": nil,
#    "lock_at": nil,
#    "unlock_at": nil,
#}
