# This represents a project that you must submit or turn in
# some sort of artifact. E.g. a file, an open ended answer,
# a URL, or even a collection of answers or inputs that you
# enter into HTML input fields.
#
# Note: these were called assignments in the old Portal code.
class Project < ApplicationRecord
  belongs_to :grade_category, optional: true

  has_one :rubric

  belongs_to :custom_content_version
  validates :custom_content_version, presence: true

  has_many :project_submissions
  has_many :users, :through => :project_submissions
  alias_attribute :submissions, :project_submissions

  # TODO: group projects? A project where there is one submission for
  # a group of people and they all get the same grade.
end
