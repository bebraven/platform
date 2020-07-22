class LtiAssignmentSelectionController < ApplicationController
  layout 'lti_placement'

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  def new
    params.require([:state])
    @assignments = CourseContent.where(content_type: 'assignment')
  end

  def create
    params.require([:state, :assignment_id])
    lti_launch = LtiLaunch.current(params[:state])
    assignment_url = course_content_url(params[:assignment_id])
    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(lti_launch, assignment_url)
  end
end
