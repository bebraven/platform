
class ProjectSubmissionAnswersController < ApplicationController
  include LtiHelper
  include DryCrud::Controllers::Nestable

  # The index can be accessed under either of these nested parents.
  nested_resource_of ProjectSubmission

  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  def index
    @project_submission_answers = ProjectSubmission.last_answers_for_submissions(@project_submission)

    # FIXME!! authorize the right thing
    authorize @project_submission

    # TODO: only return the latest for each input_name.
  end

  def create
    # FIXME!! authorize the right thing
    authorize @project_submission

    ProjectSubmissionAnswer.create_or_update_by!(
      project_submission: @project_submission,
      input_name: create_params[:input_name],
      input_value: create_params[:input_value],
    )
  end

private

  def create_params
    params.require(:project_submission_answer).permit(:input_name, :input_value)
  end
end
