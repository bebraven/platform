class ProjectSubmission < ApplicationRecord
  belongs_to :user
  belongs_to :course_project_version, foreign_key: "course_custom_content_version_id"
  has_many :project_submission_answers
  alias_attribute :answers, :project_submission_answers
  has_one :rubric_grade
  has_one :course, through: :course_project_version
  has_one :project_version, through: :course_project_version, source: :custom_content_version, class_name: 'ProjectVersion'

  # TODO: force read-only when is_submitted: true

  def project
    project_version.project
  end

  def save_answers!(_)
    # Note: ignore param and just submit this submission.
    update!(is_submitted: true)
  end
end
