class AddMissingTimestamps < ActiveRecord::Migration[6.0]
  def change
    tables = [
      "course_custom_content_versions",
      "peer_review_questions",
      "peer_review_submission_answers",
      "peer_review_submissions",
      "project_submission_answers",
      "rise360_module_states",
    ]

    tables.each do |table|
      # Handle existing records that would violate the not-null constraint by
      # defaulting their timestamps to `now` and immediately changing the default
      # to `nil` so as not to break future records.
      add_timestamps table, default: DateTime.now
      change_column_default table, :created_at, from: DateTime.now, to: nil
      change_column_default table, :updated_at, from: DateTime.now, to: nil
    end
  end
end
