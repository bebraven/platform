# This policy always checks to see whether the user is logged-in.
# Authentication is deligated to LrsXApiProxyPolicy and ProjectVersionPolicy.
class ProjectSubmissionPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    raise Pundit::NotAuthorizedError, "no project submission specified" unless record
    @user = user
    @record = record
  end

  # Access to responses submitted is handled by LrsXApiProxyPolicy.xAPI_read?.
  # If you aren't authorized, you will see a blank project form.
  # When showing a submission, you also must have permission to show the
  # associated ProjectVersion, so we check that too.
  def show?
    ProjectVersionPolicy.new(user, record.project_version).show?
  end

  # Access to previous responses is handled by LrsXApiProxyPolicy.xAPI_read?,
  # whether you can change edit answers by LrsXApiProxyPolicy.xAPI_write?.
  # When viewing the submission create form, you also must have permission to
  # show the associated ProjectVersion, so we check that too.
  def new?
    ProjectVersionPolicy.new(user, record.project_version).show?
  end

  # It doesn't really make sense to allow people to submit answers to projects
  # they aren't allowed to see, so we check the ProjectVersion show policy too.
  def create?
    ProjectVersionPolicy.new(user, record.project_version).show?
  end

  def update?
    create?
  end
end
