class LtiLaunchPolicy < ApplicationPolicy
  def login?
    true
  end

  def launch?
    # True if user logged in globally, or if there is a user attached to the
    # LTI launch record (looked up by Canvas user ID).
    !!user or !!record&.user
  end
end
