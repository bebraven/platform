class BaseCourseCustomContentVersion < ApplicationRecord
  belongs_to :base_course
  belongs_to :custom_content_version

  validates :base_course, :custom_content_version, presence: true
  validates :base_course, uniqueness: { scope: :custom_content_version }


  # Project submission needs to have access to project and course
  # so it goes on the join table
  has_many :project_submissions
  has_many :users, :through => :project_submissions
  alias_attribute :submissions, :project_submissions

  scope :projects_only, -> { includes(:custom_content_version).where(custom_content_versions: { type: 'ProjectVersion' }) }
  scope :surveys_only, -> { includes(:custom_content_version).where(custom_content_versions: { type: 'SurveyVersion' }) }

  # Finds an existing BaseCourseCustomContentVersion by parsing the URL for one.
  def self.find_by_url(url)
    id = url[/.*\/base_course_custom_content_versions\/(\d+)/, 1]
    BaseCourseCustomContentVersion.find(id) if id
  end

end
