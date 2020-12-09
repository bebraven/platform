class ProjectSubmission < ApplicationRecord
  belongs_to :user
  belongs_to :course_project_version, foreign_key: "course_custom_content_version_id"
  has_many :project_submission_answers
  alias_attribute :answers, :project_submission_answers
  has_one :rubric_grade
  has_one :course, through: :course_project_version
  has_one :project_version, through: :course_project_version, source: :custom_content_version, class_name: 'ProjectVersion'

  # TODO: force read-only when is_submitted: true
  # TODO: there can only be one is_submitted:false ???

  # Find the latest answer for each input_name attached to this project and user.
  # project_submissions can be a list or a single record.
  def self.last_answers_for_submissions(project_submissions)
    answer_ids = ProjectSubmissionAnswer.where(
      project_submission: project_submissions,
    ).select(
      'max(id) as id, input_name'
    ).group(
      :input_name
    ).map {
      |answer| answer.id
    }

    ProjectSubmissionAnswer.find(answer_ids)
  end

  def project
    project_version.project
  end


  def save_answers!
    transaction do
      # Mark as submitted and set the uniqueness_condition to NULL
      # at the same time, so our uniqueness constraint works.
      update!(is_submitted: true, uniqueness_condition: nil)

      # Immediately copy all answers to a new unsubmitted submission.
      new_submission = ProjectSubmission.create!(
        user: user,
        course_project_version: course_project_version,
        is_submitted: false,
      )
      answers.each do |answer|
        new_answer = answer.dup
        new_answer.project_submission = new_submission
        new_answer.save!
      end
    end
  end
end
