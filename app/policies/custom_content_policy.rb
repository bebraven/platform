class CustomContentPolicy < ApplicationPolicy
  def publish?
    user&.admin?
  end
end
