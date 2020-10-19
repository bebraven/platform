FactoryBot.define do
  # Represents a course returned from the canvas API
  factory :canvas_course, class: Hash do
    skip_create # This isn't stored in the DB.

    sequence(:id) 
    sequence(:name) { |i| "Test course #{i}" }
    account_id { 1 }
    uuid { "wBxjfCFN7xhbapUo8KQC4MSXtYDVIqw73lkIZMT6" }
    start_at { "2020-10-14T16:04:58Z" }
    conclude_at { "null" }
    grading_standard_id { "null" }
    is_public { "null" }
    created_at { "2020-10-14T16:04:58Z" }
    allow_student_forum_attachments { true }
    course_code { "rails" }
    default_view { "modules" }
    root_account_id { 1 }
    enrollment_term_id { 1 }
    open_enrollment { "null" }
    allow_wiki_comments { "null" }
    self_enrollment { "null" }
    license { "null" }
    restrict_enrollments_to_course_dates { false }
    grade_passback_setting { "null" }
    end_at { "null" }
    public_syllabus { false }
    public_syllabus_to_auth { false }
    storage_quota_mb { 1000 }
    is_public_to_auth_users { false }
    hide_final_grades { false }
    apply_assignment_group_weights { false }
    calendar { { "ics": "https://braven.instructure.com/feeds/calendars/course_wBxjfCFN7xhbapUo8KQC4MSXtYDVIqw73lkIZMT6.ics" } }
    time_zone { "America/New_York" }
    blueprint { false }
    sis_course_id { "null" }
    sis_import_id { "null" }
    integration_id { "null" }
    # This is set by `offer`; if offer=false, state will be 'unpublished'.
    workflow_state { "available" }

    initialize_with { attributes.stringify_keys }
  end
end

# Example
# {
#   "id": 212,
#   "name": "Course name",
#   "account_id": 1,
#   "uuid": "wBxjfCFN7xhbapUo8KQC4MSXtYDVIqw73lkIZMT6",
#   "start_at": "2020-10-14T16:04:58Z",
#   "conclude_at": null,
#   "grading_standard_id": null,
#   "is_public": null,
#   "created_at": "2020-10-14T16:04:58Z",
#   "allow_student_forum_attachments": true,
#   "course_code": "rails",
#   "default_view": "modules",
#   "root_account_id": 1,
#   "enrollment_term_id": 1,
#   "open_enrollment": null,
#   "allow_wiki_comments": null,
#   "self_enrollment": null,
#   "license": null,
#   "restrict_enrollments_to_course_dates": false,
#   "grade_passback_setting": null,
#   "end_at": null,
#   "public_syllabus": false,
#   "public_syllabus_to_auth": false,
#   "storage_quota_mb": 1000,
#   "is_public_to_auth_users": false,
#   "hide_final_grades": false,
#   "apply_assignment_group_weights": false,
#   "calendar": {
#     "ics": "https://braven.instructure.com/feeds/calendars/course_wBxjfCFN7xhbapUo8KQC4MSXtYDVIqw73lkIZMT6.ics"
#   },
#   "time_zone": "America/New_York",
#   "blueprint": false,
#   "sis_course_id": null,
#   "sis_import_id": null,
#   "integration_id": null,
#   "workflow_state": "available"
# }
