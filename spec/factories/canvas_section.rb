FactoryBot.define do
  # Represents a section returned from the canvas API
  #
  # Important: this is meant to be built with FactoryBot.json(:canvas_section)
  factory :canvas_section, class: Hash do
    skip_create # This isn't stored in the DB.
    sequence(:course_id) 
    sequence(:id) 
    sequence(:name) { |i| "Test - Section#{i}" }
    initialize_with { attributes.stringify_keys }
  end
end

# Example
#{
#    "course_id": 71,
#    "end_at": null,
#    "id": 933,
#    "integration_id": null,
#    "name": "TEST SJSU - Thursdays",
#    "nonxlist_course_id": null,
#    "sis_course_id": null,
#    "sis_import_id": null,
#    "sis_section_id": null,
#    "start_at": null
#}
