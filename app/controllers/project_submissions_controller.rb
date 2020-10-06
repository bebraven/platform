require 'lti_advantage_api'
require 'lti_score'
require 'uri'

# Viewing and submitting a project is handled by CustomContentVersion
# TODO: Migrate when we can create the project model dependencies
# TODO: https://app.asana.com/0/1174274412967132/1186960110311121
class ProjectSubmissionsController < ApplicationController
  include LtiHelper
  include DryCrud::Controllers::Nestable
  
  nested_resource_of Project

  before_action :set_project_version, only: [:create]
  before_action :set_lti_launch, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  # Project submissions aren't recorded in our DB yet (e.g, we don't use the
  # ProjectSubmission table or model).
  # TODO: https://app.asana.com/0/1174274412967132/1186960110311121
  # The fact that a student has submitted a project (e.g., clicked the "Submit"
  # button) is recorded in Canvas as an LTIScore.
  # The project responses entered by the student are recorded in the LRS and 
  # retrieved when we view the submission by xapi_assignment.js.
  def create
    authorize ProjectSubmission
    
    params.require([:state])

    # We're using CustomContentVersionsController to view and work on projects
    submission_url = Addressable::URI.parse(
      custom_content_custom_content_version_url(
        @project_version.custom_content,
        @project_version.id,
      )
    )
    submission_url.query = { user_override_id: current_user.id }.to_query

    # Save project submission to Canvas.
    # The actual project responses are stored in the LRS.
    lti_score = LtiScore.new_project_submission(
      current_user.canvas_id,
      submission_url.to_s,
    )
    LtiAdvantageAPI.new(@lti_launch).create_score(lti_score)
  end

  private
  def set_project_version
    params.require([:version])
    @project_version = CustomContentVersion.find(params[:version])
  end
end
