class NetworkPolicy < ApplicationPolicy
  def connect?
    !!user
  end

  def join?
    true
  end
end
