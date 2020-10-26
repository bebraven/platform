class ProjectSubmission < ApplicationRecord
  belongs_to :user
  belongs_to :base_course_custom_content_version
  has_one :rubric_grade

  has_one :course, through: :base_course_custom_content_version, source: :base_course, class_name: 'Course'
  has_one :project_version, through: :base_course_custom_content_version, source: :custom_content_version, class_name: 'ProjectVersion'

  # Example Usage: 
  # submissions = ProjectSubmission.for_custom_content_version_and_user(@project_submission.custom_content_version, user)
  scope :for_custom_content_version_and_user, ->(c, u) { where(base_course_custom_content_version: c, user: u) }

  def project
    project_version.project
  end
end
