require 'grade_calculator'
require 'salesforce_api'
require 'canvas_api'

class User < ApplicationRecord
  include Devise::Models::DatabaseAuthenticatable

  ADMIN_DOMAIN_WHITELIST = ['bebraven.org', 'beyondz.org']

  # We're making the user model cas_authenticable, meaning that you need to go through the SSO CAS
  # server configured in config/initializers/devise.rb. However, "that" SSO server is "this" server
  # and the users that it authenticates are created in this database using :database_authenticable
  # functionality. This article was gold to help get this working: 
  # https://jeremysmith.co/posts/2014-01-24-devise-cas-using-devisecasauthenticatable-and-casino/
  if ENV['BZ_AUTH_SERVER']
    # See: config/initializers/devise.rb for what this is all about.
    devise :cas_authenticatable, :rememberable
  else
    # TODO: trackable for more info on sign-in activity.
    #devise :cas_authenticatable, :rememberable, :registerable, :confirmable, :validatable, :recoverable, :trackable
    devise :cas_authenticatable, :rememberable, :registerable, :confirmable, :validatable, :recoverable
  end
  
  has_many :project_submissions
  has_many :projects, :through => :project_submissions
  has_many :lesson_submissions
  has_many :lessons, :through => :lesson_submissions
  has_many :program_memberships
  has_many :programs, through: :program_memberships
  has_many :roles, through: :program_memberships

  has_many :user_sections
  has_many :sections, through: :user_sections do
    def as_fellow
      merge(UserSection.enrolled)
    end

    def as_lc
      merge(UserSection.facillitates)
    end

    def as_ta
      merge(UserSection.assists)
    end
  end

  before_validation :do_account_registration, on: :create
  before_create :attempt_admin_set, unless: :admin?
  
  validates :email, uniqueness: true
  validates :email, :first_name, :last_name, presence: true
  validates :email, presence: true

  def full_name
    [first_name, last_name].join(' ')
  end
  
  def start_membership(program_id, role_id)
    find_membership(program_id, role_id) ||
      program_memberships.create(program_id: program_id, role_id: role_id, start_date: Date.today)
  end
  
  def end_membership(program_id, role_id)
    if program_membership = find_membership(program_id, role_id)
      program_membership.update! end_date: Date.yesterday
    else
      return false
    end
  end
  
  def update_membership(program_id, old_role_id, new_role_id)
    return if old_role_id == new_role_id
    
    end_membership(program_id, old_role_id)
    start_membership(program_id, new_role_id)
  end
  
  def find_membership(program_id, role_id)
    program_memberships.current.find_by(program_id: program_id, role_id: role_id)
  end
  
  def current_membership(program_id)
    program_memberships.current.find_by program_id: program_id
  end

  def total_grade(program)
    ::GradeCalculator.total_grade(self, program)
  end

  private
  
  def attempt_admin_set
    return if email.nil?
    
    domain = email.split('@').last
    self.admin = ADMIN_DOMAIN_WHITELIST.include?(domain)
  end

  # Handles anything that should happen when a new account is being registered
  # using the new_user_registration route
  def do_account_registration
    if sync_salesforce_info # They can't register for Canvas access if they aren't Enrolled in Salesforce
      setup_canvas_access
    end
  end

  # Grabs the values from Salesforce and sets them on this User since SF is the source of truth
  def sync_salesforce_info
    return false unless salesforce_id
    sf_info = SalesforceAPI.client.get_contact_info(salesforce_id)
    self.first_name = sf_info['FirstName']
    self.last_name = sf_info['LastName']
    self.email = sf_info['Email']
    raise SalesforceAPI::SalesforceDataError.new("Contact info sent from Salesforce missing data: #{sf_info}") unless first_name && last_name && email
    true
  rescue => e
    Rails.logger.error(e)
    throw :abort # Makes active record do the expected thing for save/create
  end

  # Looks up their Canvas account and sets the Id so that on login we can redirect them there.
  def setup_canvas_access
    return if canvas_id
    existing_user = CanvasAPI.client.find_user_in_canvas(email)
    if existing_user
      self.canvas_id = existing_user['id']
    else
      Rails.logger.error("User is trying to create an account but is not in Canvas: #{inspect}")
      throw :abort # TODO: create them on the fly by running a Sync To LMS for just this user. Maybe it just wasn't run yet.
    end
  end


end
