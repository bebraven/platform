class Section < ApplicationRecord
  resourcify

  belongs_to :logistic
  belongs_to :course, -> {
    where(base_courses: { type: 'Course' })
  }, foreign_key: :base_course_id

  before_validation { name.try(:strip!) }

  # All users, with any role, in this section.
  # This is a function just because I don't know how to write it as an association.
  def users
    all_users = []
    roles.distinct.map { |r| r.name }.each do |role_name|
      all_users += User.with_role(role_name, self)
    end
    all_users.uniq
  end

end
