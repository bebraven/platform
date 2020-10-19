class CustomContentVersionPolicy < ApplicationPolicy
  def show?
    !user.nil?
  end
end
