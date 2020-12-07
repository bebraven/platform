
# Support multiple submissions, but only one draft
class ProjectSubmissionAnswer < ApplicationRecord
  belongs_to  :project_submission
  has_one :user, through: :project_submission
  has_one :course_project_version, through: :project_submission

  validates :project_submission, :input_name, presence: true

  def self.create_or_update_by!(project_submission:, input_name:, input_value:)
    transaction do
      answer = create_or_find_by!(
        project_submission: project_submission,
        input_name: input_name,
      )
      answer.update!(input_value: input_value)
    end
  end
end
