class BaseCoursePolicy < ApplicationPolicy
  def launch_new?
    new?
  end

  def launch_create?
    create?
  end
end
