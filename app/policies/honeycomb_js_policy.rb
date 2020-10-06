# Only available to logged-in users, so return false if user is nil.
class HoneycombJsPolicy < ApplicationPolicy
  def send_span?
    !!user
  end
end
