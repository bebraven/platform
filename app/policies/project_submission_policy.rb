class ProjectSubmissionPolicy < ApplicationPolicy
  def create?
    !!user
  end
end
