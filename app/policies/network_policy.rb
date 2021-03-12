class NetworkPolicy < ApplicationPolicy
  def connect?
    !!user
  end

  def join?
    true
  end

  def create_champion?
    true
  end
end
