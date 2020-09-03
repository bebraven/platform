class LtiAssignmentSelectionController < ApplicationController
  include LtiHelper
  layout 'lti_placement'

  before_action :set_lti_launch, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:new, :create], if: :is_sessionless_lti_launch?

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  def new
    params.require([:state])
    @assignments = CourseContent.where(content_type: 'assignment')

    # TODO: everything after this is bad :(
    @surveys = CourseContent.where(content_type: 'form')

    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(@lti_launch,
      form_submissions_peer_review_url)
  end

  # TODO: this should be in the ProjectsController or a new ProjectContentsController create, not here.
  # "LTI Assignment selection" is a canvas concept. Both Lessons and Projects are assignments in canvas, 
  # but lesson_contents and project_contents should be what we create in Platform.
  # https://app.asana.com/0/1174274412967132/1186960110311121
  def create
    params.require([:state, :assignment_id])

    cc = CourseContent.find(params[:assignment_id])
    cc.save_version!(current_user)

    assignment_url = course_content_course_content_history_url(
      params[:assignment_id],
      cc.last_version.id,
    )
    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(@lti_launch, assignment_url)
  end

end
