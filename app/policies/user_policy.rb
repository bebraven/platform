class UserPolicy < ApplicationPolicy
  def confirm?
    update?
  end
end
