FactoryBot.define do
  # Represents a course returned from the canvas API
  factory :canvas_content_migration, class: Hash do
    skip_create # This isn't stored in the DB.

    sequence(:id) 
    sequence(:user_id)  # the user who started the migration
    workflow_state { "running" }
    started_at { "2020-10-14T16:25:10Z" }
    finished_at { "null" }  # timestamp if finished
    migration_type { "course_copy_importer" }
    created_at { "2020-10-14T16:25:09Z" }
    # Course ID below is the desination for the migration.
    migration_issues_url { "https://braven.instructure.com/api/v1/courses/212/content_migrations/#{id}/migration_issues" }
    migration_issues_count { 0 }
    sequence(:settings) { |i| {
      "source_course_id": i,
      "source_course_name": "Source Course #{i}",
      "source_course_html_url": "https://braven.instructure.com/courses/#{i}",
    } }
    sequence(:progress_url) { |i| "https://braven.instructure.com/api/v1/progress/#{i}" }
    migration_type_title { "Course Copy" }  # matches the migration_type

    initialize_with { attributes.stringify_keys }
  end
end

# Example
# {
#   "id": 186,
#   "user_id": 81,
#   "workflow_state": "running",
#   "started_at": "2020-10-14T16:25:10Z",
#   "finished_at": null,
#   "migration_type": "course_copy_importer",
#   "created_at": "2020-10-14T16:25:09Z",
#   "migration_issues_url": "https://braven.instructure.com/api/v1/courses/212/content_migrations/186/migration_issues",
#   "migration_issues_count": 0,
#   "settings": {
#     "source_course_id": 42,
#     "source_course_name": "Playground - Ryan",
#     "source_course_html_url": "https://braven.instructure.com/courses/42"
#   },
#   "progress_url": "https://braven.instructure.com/api/v1/progress/361",
#   "migration_type_title": "Course Copy"
# }
