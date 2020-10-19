class LessonContentPolicy < ApplicationPolicy
  def show?
    !!user
  end
end
