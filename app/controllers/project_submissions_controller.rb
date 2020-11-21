require 'lti_advantage_api'
require 'lti_score'

class ProjectSubmissionsController < ApplicationController
  include LtiHelper
  include DryCrud::Controllers::Nestable
  
  layout 'lti_canvas'

  nested_resource_of BaseCourseProjectVersion

  before_action :set_lti_launch
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  def show
    authorize @project_submission
    # Setting this here b/c we use the root path instead of a nested path for viewing project submissions.
    @base_course_project_version = @project_submission.base_course_project_version
    @user_override_id = @project_submission.user.id
    @project_lti_id = @lti_launch.activity_id
  end

  def new
    @project_submission = ProjectSubmission.new(
      user: current_user,
      base_course_project_version: @base_course_project_version,
    )
    authorize @project_submission

    @has_previous_submission = ProjectSubmission.where(
      base_course_project_version: @base_course_project_version,
      user: @project_submission.user,
    ).exists?

    @project_lti_id = @lti_launch.activity_id
  end

  # Eventually, we'll store the responses in the ProjectSubmission itself.
  # TODO: https://app.asana.com/0/1174274412967132/1197477442813577
  # For now, we use the ProjectSubmission's created_at time to query the LRS
  # when we view the submission. (See xapi_assignment.js.)
  # We also record an LTIScore in Canvas so the submission is visible through
  # the SpeedGrader.
  def create
    # Create a submission for this user and project
    @project_submission = ProjectSubmission.new(
      user: current_user,
      base_course_project_version: @base_course_project_version,
    )
    authorize @project_submission
    @project_submission.save!

    # Save project submission to Canvas.
    # The actual project responses are stored in the LRS.
    lti_score = LtiScore.new_project_submission(
      current_user.canvas_user_id,
      project_submission_url(@project_submission),
    )
    LtiAdvantageAPI.new(@lti_launch).create_score(lti_score)
  end

end
