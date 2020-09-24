class Course < BaseCourse
  has_many :course_memberships
  has_many :users, through: :course_memberships
  has_many :roles, through: :course_memberships
end
