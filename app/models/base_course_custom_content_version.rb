class BaseCourseCustomContentVersion < ApplicationRecord
  MissingCanvasAssignmentIdError = Class.new(StandardError)
  belongs_to :base_course
  belongs_to :custom_content_version

  validates :base_course, :custom_content_version, presence: true
  validates :base_course, uniqueness: { scope: :custom_content_version }

  # Project submission needs to have access to project and course
  # so it goes on the join table
  has_many :project_submissions
  has_many :users, :through => :project_submissions
  alias_attribute :submissions, :project_submissions

  scope :with_project_versions, -> { includes(:custom_content_version).where(custom_content_versions: { type: 'ProjectVersion' }) }
  scope :with_survey_versions, -> { includes(:custom_content_version).where(custom_content_versions: { type: 'SurveyVersion' }) }

  def canvas_url
    # TODO: add a validation and make the column constraint be non-null.
    # https://app.asana.com/0/1174274412967132/1198965066699365
    raise MissingCanvasAssignmentIdError, "BaseCourseCustomContentVersion[#{inspect}] has no canvas_assignment_id" unless canvas_assignment_id
    "#{Rails.application.secrets.canvas_url}/courses/#{base_course.canvas_course_id}/assignments/#{canvas_assignment_id}"
  end

  # Finds an existing BaseCourseCustomContentVersion by parsing the URL for one.
  def self.find_by_url(url)
    id = url[/.*\/base_course_custom_content_versions\/(\d+)/, 1]
    BaseCourseCustomContentVersion.find(id) if id
  end

end
