class LrsXapiProxyPolicy < ApplicationPolicy
  attr_reader :user, :target_user

  def initialize(user, target_user)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @target_user = target_user
  end

  def xAPI_read?
    # Can always read your own data.
    return true if user == target_user
    # Make sure target_user isn't nil.
    return false if !target_user
    # TAs can read the data for students in their sections.
    user.ta_for?(target_user)
  end

  def xAPI_write?
    # Can only write your own data.
    user == target_user
  end
end
