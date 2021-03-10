require 'grade_calculator'
require 'salesforce_api'
require 'canvas_api'
require 'sync_to_lms'

class User < ApplicationRecord
  rolify
  include Devise::Models::DatabaseAuthenticatable

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

  validates :email, uniqueness: true
  validates :email, :first_name, :last_name, presence: true
  validates :email, presence: true

  def full_name
    [first_name, last_name].compact.join(' ')
  end

  # All sections where this user has any role.
  # This is a function just because I don't know how to write it as an association.
  def sections
    Section.with_roles(roles.distinct.map { |r| r.name }, self).distinct
  end

  # All sections with a specific role.
  def sections_with_role(role_name)
    Section.with_roles(role_name, self).distinct
  end

  # True if the user has confirmed their account and can login.  
  def confirmed?
    !!confirmed_at
  end

  def admin?
    has_role? :admin
  end

  # True if this user is a TA in the same section where target_user is a student.
  def ta_for?(target_user)
    sections_with_role(RoleConstants::TA_ENROLLMENT).each do |section|
      return true if target_user.has_role? RoleConstants::STUDENT_ENROLLMENT, section
    end
    false
  end

  def total_grade(base_course)
    ::GradeCalculator.total_grade(self, base_course)
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
  
  # Handles anything that should happen when a new account is being registered
  # using the new_user_registration route
  def do_account_registration
    Rails.logger.info('Starting account registration')
    if sync_salesforce_info # They can't register for Canvas access if they aren't Enrolled in Salesforce
      setup_canvas_access
      Rails.logger.info('Done setting up canvas access')
      store_canvas_user_id_in_salesforce
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
    return if canvas_user_id

    Rails.logger.info("Setting up Canvas account and enrollments for user: #{inspect}")
    self.canvas_user_id = SyncToLMS.new.for_contact(salesforce_id)
  end

  def store_canvas_user_id_in_salesforce
    SalesforceAPI.client.set_canvas_user_id(salesforce_id, canvas_user_id)
  end
end
