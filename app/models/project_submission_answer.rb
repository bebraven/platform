
# Support multiple submissions, but only one draft
class ProjectSubmissionAnswer < ApplicationRecord
  # Unsubmitted
  belongs_to :user
  belongs_to :base_course_project_version, foreign_key: "base_course_custom_content_version_id"

  # Submitted
  belongs_to  :project_submission

  has_one :course, through: :base_course_project_version, source: :base_course, class_name: 'Course'
  has_one :project_version, through: :base_course_project_version, source: :custom_content_version, class_name: 'ProjectVersion'

  # TODO: Validate that project_submission and user/bcccv are mutually exclusive

  def update_or_create_by!(user, base_course_project_version, input_name, input_value)
    answer = ProjectSubmissionAnswer.find_or_create_by!(
      user: current_user,
      base_course_custom_content_version: base_course_custom_content_version,
      input_name: params[:input_name],
    )
    answer.update!(input_value: params[:input_value])
  end

  def is_submitted
    !!self.survey_submission
  end
end
