require 'lti_advantage_api'
require 'lti_score'
require 'uri'

class ProjectSubmissionsController < ApplicationController
  include LtiHelper
  include DryCrud::Controllers::Nestable
  
  layout 'projects'

  nested_resource_of BaseCourseCustomContentVersion

  before_action :set_lti_launch
  before_action :set_course_content_version, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  def show
    authorize @project_submission
    @course_content_version = @project_submission.base_course_custom_content_version
    @user_override_id = @project_submission.user.id
    @project_lti_id = @lti_launch.activity_id
  end

  def new
    @project_submission = ProjectSubmission.new(
      user: current_user,
      base_course_custom_content_version: @course_content_version,
    )
    authorize @project_submission

    @has_previous_submission = ProjectSubmission.for_custom_content_version_and_user(
      @course_content_version.custom_content_version,
      @project_submission.user,
    ).exists?

    @project_lti_id = @lti_launch.activity_id if @lti_launch
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
      base_course_custom_content_version: @course_content_version,
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

  private
  def set_course_content_version
    params.require([:base_course_custom_content_version_id])
    @course_content_version = BaseCourseCustomContentVersion.find(params[:base_course_custom_content_version_id])
  end
end
