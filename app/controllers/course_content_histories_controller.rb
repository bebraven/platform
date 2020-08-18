# This controller currently handles viewing and filling in ansewrs in a 
# project. 
# Submitting a project is handled by ProjectSubmissionsController.
# TODO: https://app.asana.com/0/1174274412967132/1186960110311121
class CourseContentHistoriesController < ApplicationController
  include DryCrud::Controllers::Nestable
  nested_resource_of CourseContent
  layout 'content_editor'

  # TODO: Only for sessionless launches: https://app.asana.com/0/1174274412967132/1188539121871585
  skip_before_action :verify_authenticity_token, only: [:create] 

  before_action :set_course_content, only: [:index, :show, :create]

  # GET /course_contents/:id/versions
  # GET /course_contents/:id/versions.json
  def index
  end

  # GET /course_contents/:id/versions/1
  # GET /course_contents/:id/versions/1.json
  def show
    params.require([:course_content_id])

    # TODO: https://app.asana.com/0/1174274412967132/1187445581799823
    # We can also view this when adding an assignment in Canvas in
    # the iframe preview mode:
    # app/views/lti_assignment_selection/create.html.erb
    # Clean this up so we don't try to communicate with the LRS in this
    # case.

    # Viewed in platformweb as published version of project
    unless params[:state]
      # Shows a version of the project
      return
    end

    # TODO: https://app.asana.com/0/1174274412967132/1185569091008475
    # Make sure the currently logged in user has access to view the
    # submission for this override_user_id.
    # Must be the student themselves or a TA or staff who has access.
    # Need to use Canvas roles to check.

    # Viewed in Canvas as a project submission for this version of the project
    # For a student, this will load the project, populate the student's
    # most recent answers from the LRS, and allow them to submit the project.
    # For a TA, this will do the same as above, but in read-only mode.
    # The answers showns are the most recent entered by the student, at
    # the granularity of the input fields, not at the granularity of
    # a submission.
    # Specifying a override_user_id indicates a TA is viewing a student's
    # submission.
    @user_override_id = params[:user_override_id]
    @lti_auth_state = params[:state]
    @project_lti_id = LtiLaunch.current(params[:state]).activity_id
  end

  private
    def set_course_content
      @course_content = CourseContent.find(params[:course_content_id])
    end
end
