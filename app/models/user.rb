require 'grade_calculator'
require 'salesforce_api'
require 'canvas_api'
require 'sync_to_lms'

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

  self.per_page = 100
  
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

  # before_validation :do_account_registration, on: :create
  before_create :attempt_admin_set, unless: :admin?
  
  validates :email, uniqueness: true
  validates :email, :first_name, :last_name, presence: true
  validates :email, presence: true

  def full_name
    [first_name, last_name].join(' ')
  end

  # True if the user has confirmed their account and can login.  
  def confirmed?
    !!confirmed_at
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

  def self.search(query)
    search_str = query.strip
    search_str.downcase!
    to_sql_pattern = ->(str) { "%#{str.gsub('*', '%')}%" } # 'ian*test@bebrave' would turn into '%ian%test@bebrave%' and SQL would return the email: 'brian+testblah@bebraven.org'
    if search_str.include? '@'
      where('lower(email) like ?', to_sql_pattern[search_str] )
    else 
      search_terms = search_str.split("\s")
      if search_terms.size <= 1
        pattern = to_sql_pattern[search_str]
        where('lower(first_name) like ? OR lower(last_name) like ? OR lower(email) like ?', pattern, pattern, pattern)
      else
        where('lower(first_name) like ? AND lower(last_name) like ?', to_sql_pattern[search_terms.first], to_sql_pattern[search_terms.last])
      end
    end
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
    Rails.logger.info('Starting account registration')
    if sync_salesforce_info # They can't register for Canvas access if they aren't Enrolled in Salesforce
      setup_canvas_access
      Rails.logger.info('Done setting up canvas access')
      store_canvas_id_in_salesforce
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
  end

  # Looks up their Canvas account and sets the Id so that on login we can redirect them there.
  def setup_canvas_access
    return if canvas_id

    Rails.logger.info("Setting up Canvas account and enrollments for user: #{inspect}")
    self.canvas_id = SyncToLMS.new.for_contact(salesforce_id)
  end

  def store_canvas_id_in_salesforce
    SalesforceAPI.client.set_canvas_id(salesforce_id, canvas_id)
  end
end
