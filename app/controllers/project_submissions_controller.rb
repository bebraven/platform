require 'lti_advantage_api'
require 'lti_score'
require 'uri'

class ProjectSubmissionsController < ApplicationController
  include LtiHelper
  include DryCrud::Controllers::Nestable
  
  layout 'projects'

  nested_resource_of Project

  before_action :set_project
  before_action :set_lti_launch
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  def show
    authorize @project_submission

    @user_override_id = @project_submission.user.id
    @custom_content_version = @project.custom_content_version
    @project_lti_id = @lti_launch.activity_id
  end

  def new
    @project_submission = ProjectSubmission.new
    authorize @project_submission

    @custom_content_version = @project.custom_content_version
    @has_previous_submission = LtiAdvantageAPI
      .new(@lti_launch)
      .get_line_item_for_user(current_user.canvas_user_id)
      .present?
    @project_lti_id = @lti_launch.activity_id
  end

  # Project submissions aren't recorded in our DB yet.
  # The fact that a student has submitted a project (e.g., clicked the "Submit"
  # button) is recorded in Canvas as an LTIScore.
  # The project responses entered by the student are recorded in the LRS and 
  # retrieved when we view the submission by xapi_assignment.js.
  def create
    # Create a submission for this user and project
    @project_submission = ProjectSubmission.new(
      user: current_user,
      project: @project,
    )
    authorize @project_submission
    @project_submission.save!

    # Save project submission to Canvas.
    # The actual project responses are stored in the LRS.
    lti_score = LtiScore.new_project_submission(
      current_user.canvas_user_id,
      project_project_submission_url(
        @project_submission.project,
        @project_submission,
      ),
    )
    LtiAdvantageAPI.new(@lti_launch).create_score(lti_score)
  end

  private
  def set_project
    params.require([:project_id])
    @project = Project.find(params[:project_id])
  end
end
