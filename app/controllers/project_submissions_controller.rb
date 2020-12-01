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

  def show
    authorize @project_submission
    @read_only = true
    @unsubmitted_answers = nil
  end

  def new
    @project_submission = ProjectSubmission.new(
      user: current_user,
      course_project_version: @course_project_version,
    )
    authorize @project_submission

    @read_only = false
    
    # Get most recent answers
    @unsubmitted_answers = ProjectSubmissionAnswers.where(
      base_course_project_version: @base_course_project_version,
      user:  @project_submission.user,
      project_submission: nil, # TODO: This is redundant after adding validation
    )

    # TODO: Put this in a helper
    @has_previous_submission = ProjectSubmission.where(
      course_project_version: @course_project_version,
      user: @project_submission.user,
    ).exists?
  end

private
  # Called by Submittable.new.
  def allow_multiple_submissions
    true
  end

  # Called by Submittable.create.
  def answers_params_hash
    # We ignore all the params and look at ProjectSubmissionAnswers
    {}
  end
end
