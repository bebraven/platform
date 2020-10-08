# This policy only checks to see whether the user is logged-in.
# Authentication is deligated to LrsXApiProxyPolicy and Canvas.
class ProjectSubmissionPolicy < ApplicationPolicy
  # Any logged-in user can view a project submission.
  # Access to responses submitted is handled by LrsXApiProxyPolicy.xAPI_read?.
  # If you aren't authorized, you will see a blank project form.
  def show?
    !!user
  end

  # Any logged-in user can see the submission creation page.
  # Access to previous responses is handled by LrsXApiProxyPolicy.xAPI_read?,
  # whether you can change edit answers by LrsXApiProxyPolicy.xAPI_write?.
  def new?
    !!user
  end

  # Any logged-in user can attempt to create a submission.
  # We rely on Canvas to verify whether the user is a student in the course.
  def create?
    !!user
  end
end
