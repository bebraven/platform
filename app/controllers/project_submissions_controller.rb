require 'lti_advantage_api'
require 'lti_score'

class ProjectSubmissionsController < ApplicationController
  include LtiHelper

  include DryCrud::Controllers::Nestable

  # Note we're not using Submittable here, since the behavior for projects differs
  # significantly from other Submittables.

  nested_resource_of CourseProjectVersion

  layout 'lti_canvas'

  before_action :set_lti_launch
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  before_action :set_has_previous_submission, only: [:edit, :new]

  def show
    authorize @project_submission
    @unsubmitted_answers = nil
  end

  # Note: this should only be called on unsubmitted submissions.
  def edit
    authorize @project_submission
    render plain: 'Not allowed to edit previous submissions', status: 403 and return if @project_submission.is_submitted
  end

  def create
    authorize instance_variable

    # Record in our DB first, so we have the data even if updating Canvas fails.
    instance_variable.save_answers!

    # Update Canvas
    # TODO: project submission.
    lti_score = LtiScore.new_full_credit_submission(
      @current_user.canvas_user_id,
      # E.g. survey_submission_url(@survey_submission, protocol: 'https').
      self.send("#{instance_variable_name}_url", instance_variable, protocol: 'https'),
    )
    LtiAdvantageAPI.new(@lti_launch).create_score(lti_score)

    redirect_to instance_path(instance_variable)
  end

  def update
  end

  # NOTE: This action exhibits nonstandard behavior!!
  # See redirect below.
  def new
    # Only `new` if there is no existing unsubmitted submission.
    # Otherwise, force a redirect to the unsubmitted's /edit.
    unsubmitted_submission = ProjectSubmission.find_by(
      user: current_user,
      course_project_version: @course_project_version,
      is_submitted: false,
    )

    if unsubmitted_submission
      authorize unsubmitted_submission
      redirect_to edit_course_project_version_project_submission_path(
        @course_project_version,
        unsubmitted_submission
      ) and return
    end

    # Standard `new` action behavior after this point.
    @project_submission = ProjectSubmission.new(
      user: current_user,
      course_project_version: @course_project_version,
      is_submitted: false,
    )
    authorize @project_submission
  end

private

  def set_has_previous_submission
    @has_previous_submission = ProjectSubmission.where(
      course_project_version: @course_project_version,
      user: @project_submission.user,
      is_submitted: true,
    ).exists?
  end

end
