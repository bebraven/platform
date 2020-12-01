class ProjectSubmission < ApplicationRecord
  belongs_to :user
  belongs_to :course_project_version, foreign_key: "course_custom_content_version_id"
  has_one :rubric_grade
  has_one :course, through: :course_project_version
  has_one :project_version, through: :course_project_version, source: :custom_content_version, class_name: 'ProjectVersion'

  def project
    project_version.project
  end

  def save_answers!(input_values_by_name)
    # Note: ignore input_values_by_name and look at unsubmitted answers saved
    # in our database
    transaction do  
      # Get unsubmitted answers
      answers = ProjectSubmissionAnswer.where(
        user: user,
        base_course_project_version: base_course_project_version,
        project_submission: nil,
      )
    
      # Attach the answers to this submission
      answers.map do |answer|
        answer.update!(
          project_submission: self,
          base_course_project_version: nil,
          user: nil,
          input_name: input_name,
          input_value: input_value,
        )
      end

      save!
    end
  end
end
