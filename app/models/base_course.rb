class BaseCourse < ApplicationRecord
  belongs_to :course_resource, optional: true

  has_many :base_course_custom_content_versions
  has_many :custom_content_versions, :through => :base_course_custom_content_versions

  # These are the published project content versions associated, but not the actual join table from BaseCourse to ProjectVersion
  has_many :project_versions, -> { project_versions }, through: :base_course_custom_content_versions, source: :custom_content_version, class_name: 'ProjectVersion'

  has_many :grade_categories
  has_many :lessons, :through => :grade_categories

  before_validation do
    name.strip!
  end

  # TODO: putting these "virtual" attributes here for now. In the next iteration, we'll want to
  # store this stuff in the database and have a way to update our local database values with the
  # Salesforce values since that's the source of truth.
  # Note tht if/when we start storing these in teh database, we can remove this explicitly since ActiveRecord sets it up for columns
  attr_accessor :salesforce_id, :salesforce_school_id, :fellow_course_id, :leadership_coach_course_id, :leadership_coach_course_section_name,
                :timezone, :docusign_template_id, :pre_accelerator_qualtrics_survey_id, :post_accelerator_qualtrics_survey_id, :lc_docusign_template_id

  # PROPOSAL: as we model this out, here is goal I want to propose:
  # Divorce the logic of how a "course" is laid out including what content, projects, lessons
  # grading rules, etc from the logic needed to actually execute a course and the logistics
  # inolved in running it. E.g. the people in it, their role, the due dates, the submissions,
  # etc.
  #
  # We shouldn't have to copy everything over and over again when it's the same "course."
  # A "course_template" should just point to a course and have all the administration / logistics
  # tied to the course_template. So a course is an "instance" of a course_template that we are
  # executing for a given semester at a given school.

  validates :name, :type, presence: true

  scope :courses, -> { where type: 'Course' }
  scope :course_templates, -> { where type: 'CourseTemplate' }

  def to_show
    attributes.slice('name')
  end

  def custom_contents
    custom_content_versions.map { |v| v.custom_content }
  end

  def projects
    project_versions.map { |v| v.project }
  end

  def base_course_project_versions
    base_course_custom_content_versions.projects_only
  end

  def base_course_survey_versions
    base_course_custom_content_versions.surveys_only
  end

  def canvas_url
    "#{Rails.application.secrets.canvas_url}/courses/#{canvas_course_id}"
  end

  def verify_can_edit!
    unless can_edit?
      raise NotImplementedError, "Only editing Course Templates is currently supported, not an already launched Course[#{inspect}]"
    end
  end

  def can_edit?
    !!self.is_a?(CourseTemplate)
  end
end
