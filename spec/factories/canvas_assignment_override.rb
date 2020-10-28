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

    factory :canvas_assignment_override_section do
      sequence(:title) { |i| "Test - Section#{i}" }
      sequence(:course_section_id)
    end

    initialize_with { attributes.stringify_keys }
  end
end

# Example
#{
#    "id": 208,
#    "assignment_id": 816,
#    "course_section_id": 226,
#    "title": "Monday, 6pm",
#    "due_at": nil,
#    "all_day": false,
#    "all_day_date": nil,
#}
