class CourseResourcePolicy < ApplicationPolicy
  def lti_show?
    !!user
  end
end
