class Program < ApplicationRecord
  belongs_to :organization
  
  has_many :program_memberships
  has_many :users, through: :program_memberships
  has_many :roles, through: :program_memberships

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
  # A "program" should just point to a course and have all the administration / logistics
  # tied to the program. So a program is an "instance" of a course that we are executing for
  # a given semester at a given school. 

  validates :name, presence: true

  def to_show
    attributes.slice('name')
  end
end
