class NetworkPolicy < ApplicationPolicy
  def connect?
    !!user
  end
end
