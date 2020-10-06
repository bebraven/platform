# KeypairController is not behind a login, so we don't have access to @user.
# Just return `true` from any action we need to call.

class KeypairPolicy < ApplicationPolicy
  def index?
    true
  end
end
