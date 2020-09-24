class Role < ApplicationRecord
  has_many :course_memberships
  has_many :users, through: :course_memberships
  has_many :courses, through: :course_memberships
  
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  
  def to_show
    attributes.slice('name')
  end
end
