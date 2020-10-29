class CustomContentVersion < ApplicationRecord
  belongs_to :custom_content
  alias_attribute :parent, :custom_content
  belongs_to :user

  has_many :base_course_custom_content_versions
  has_many :base_courses, through: :base_course_custom_content_versions

  has_many :courses, -> { courses }, through: :base_course_custom_content_versions, source: :base_course, class_name: 'Course'
  has_many :course_templates, -> { course_templates }, through: :base_course_custom_content_versions, source: :base_course, class_name: 'CourseTemplate'

  scope :project_versions, -> { where type: 'ProjectVersion' }
  scope :survey_versions, -> { where type: 'SurveyVersion' }
end
