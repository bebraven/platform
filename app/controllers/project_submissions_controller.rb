require 'lti_advantage_api'
require 'lti_score'

class ProjectSubmissionsController < ApplicationController

  include DryCrud::Controllers::Nestable

  # Not quite like submittable because that's Submittable
  # ReSubmittable?
  # This will redirect to #show after you submit
  include Submittable
  nested_resource_of CourseProjectVersion

  layout 'lti_canvas'

  before_action :set_lti_launch
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  before_action :set_user, only: [:index]


  # Nonstandard action for API use.
  def fill_answers
    @previous_submission = ProjectSubmission.where(
      user: @user,
      course_project_version: @course_project_version,
      is_submitted: true,
    ).last
    @current_submission = ProjectSubmission.where(
      user: @user,
      course_project_version: @course_project_version,
      is_submitted: true,
    )
  end

  def show
    authorize @project_submission
    @read_only = true
    @unsubmitted_answers = nil
  end

  # NOTE: This action exhibits nonstandard behavior!!
  def new
    # Only `new` if there is no existing unsubmitted submission.
    if unsubmitted_submission
      @project_submission = unsubmitted_submission
    else
      @project_submission = ProjectSubmission.new(
        user: current_user,
        course_project_version: @course_project_version,
        is_submitted: false,
      )
    end

    authorize @project_submission

    @read_only = false

    # TODO: Put this in a helper
    @previous_submission = ProjectSubmission.where(
      course_project_version: @course_project_version,
      user: @project_submission.user,
      is_submitted: true,
    ).last
    
    # Get most recent answers.
    @unsubmitted_answers = ProjectSubmissionAnswer.where(
      project_submission: [@project_submission, @previous_submission],
    )
  end

private
  def unsubmitted_submission
    ProjectSubmission.find_by(
      user: current_user,
      course_project_version: @course_project_version,
      is_submitted: false,
    )
  end

  # Called by Submittable.new.
  def allow_multiple_submissions
    true
  end

  # Called by Submittable.create.
  def answers_params_hash
    # We ignore all the params and look at ProjectSubmissionAnswers.
    {}
  end
end
