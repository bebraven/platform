# Since Platform is mostly admin-only, we set the default policy to disallow all but
# admin users to view each of the standard actions. Note that this policy does not
# automatically apply; policies must be explicitly added to each action in each
# controller with the `authorize` function. To use this policy directly in controllers
# that do not reference a model, like `home_controller`, call `authorize :application`.

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def new?
    create?
  end

  def update?
    user&.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user&.admin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
