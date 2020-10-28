FactoryBot.define do
  # Represents a Progress object returned from the canvas API
  # See: https://canvas.instructure.com/doc/api/progress.html#Progress
  #
  # Important: this is meant to be built with FactoryBot.json(:canvas_progress)
  factory :canvas_progress, class: Hash do
    skip_create # This isn't stored in the DB.

    sequence(:id) 
    sequence(:context_id)                          # the context owning the job
    sequence(:user_id)                             # the user who started the migration or other job whose progress we're checking
    workflow_state { "running" }                   # queued, running, completed, failed
    created_at { "2020-10-14T16:25:09Z" }
    updated_at { "2020-10-14T16:26:10Z" }
    sequence(:completion) { |i| i.to_f }           # the percent complete
    message { nil }
    sequence(:url) { |i| "https://braven.instructure.com/api/v1/progress/#{i}" }

    factory :canvas_content_migration_progress do
      context_type {'ContentMigration'} # the context owning the job
      tag {'content_migration'}         # the type of operation
    end

    initialize_with { attributes.stringify_keys }
  end
end

# Example
# {
#   "id": 186,
#   "context_id" : 143,
#   "context_type" : "ContentMigration",
#   "tag" : "content_migration",
#   "user_id": 78,
#   "workflow_state": "running",
#   "created_at": "2020-10-14T16:25:10Z",
#   "updated_at": "2020-10-14T16:26:12Z",
#   "completion": 45.0,
#   "message": nil,
#   "url": "https://braven.instructure.com/api/v1/progress/361",
# }
