class Course < ApplicationRecord
  CourseEditError = Class.new(StandardError)
  belongs_to :course_resource, optional: true

  scope :launched_courses, -> { where is_launched: true }
  scope :unlaunched_courses, -> { where is_launched: false }

  has_many :sections

  has_many :course_rise360_module_versions
  has_many :rise360_module_versions, :through => :course_rise360_module_versions

  has_many :course_custom_content_versions
  has_many :custom_content_versions, :through => :course_custom_content_versions

  # These are the published versions of project and survey content associated with this course.
  # Note: they are not the actual join table records from Course to ProjectVersion or SurveyVersion
  has_many :project_versions, -> { project_versions }, through: :course_custom_content_versions, source: :custom_content_version, class_name: 'ProjectVersion'
  has_many :survey_versions, -> { survey_versions }, through: :course_custom_content_versions, source: :custom_content_version, class_name: 'SurveyVersion'

  # These are the actual join table records the represent a published ProjectVersion or SurveyVersion
  # to a particular Course
  has_many :course_project_versions, -> { course_project_versions}, source: :course_custom_content_version, class_name: 'CourseProjectVersion'
  has_many :course_survey_versions, -> { course_survey_versions}, source: :course_custom_content_version, class_name: 'CourseSurveyVersion'

  has_many :course_attendance_events
  has_many :attendance_events, :through => :course_attendance_events

  has_many :grade_categories
  has_many :lessons, :through => :grade_categories

  before_validation do
    name.strip!
  end

  # TODO: putting these "virtual" attributes here for now. In the next iteration, we'll want to
  # store this stuff in the database and have a way to update our local database values with the
  # Salesforce values since that's the source of truth.
  # Note tht if/when we start storing these in teh database, we can remove this explicitly since ActiveRecord sets it up for columns
  attr_accessor :salesforce_id, :salesforce_school_id, :fellow_course_id, :leadership_coach_course_id,
                :timezone, :pre_accelerator_qualtrics_survey_id, :post_accelerator_qualtrics_survey_id

  validates :name, presence: true

  def to_show
    attributes.slice('name')
  end

  def rise360_modules
    rise360_module_versions.map { |m| m.rise360_module }
  end

  def custom_contents
    custom_content_versions.map { |v| v.custom_content }
  end

  def projects
    project_versions.map { |v| v.project }
  end

  def surveys
    survey_versions.map { |v| v.survey }
  end

  def students
    sections.map { |s| s.students }.flatten.uniq
  end

  def canvas_url
    "#{Rails.application.secrets.canvas_url}/courses/#{canvas_course_id}"
  end

  def canvas_rubrics_url
    "#{Rails.application.secrets.canvas_url}/courses/#{canvas_course_id}/rubrics"
  end

  def verify_can_edit!
    unless can_edit?
      raise CourseEditError, "Only editing Course Templates is currently supported, not an already launched Course[#{inspect}]"
    end
  end

  def can_edit?
    self.is_launched == false
  end
end
