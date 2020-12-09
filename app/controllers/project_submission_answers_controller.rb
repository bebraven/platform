
class ProjectSubmissionAnswersController < ApplicationController
  include DryCrud::Controllers::Nestable

  # The index can be accessed under either of these nested parents.
  nested_resource_of [CourseProjectVersion, ProjectSubmission]

  def index
    @project_submission_answers = ProjectSubmission.last_answers_for_submissions(
      # If nested under project_submission, use that ID. Otherwise,
      # use the course_project_version ID and current_user.
      @project_submission || [ProjectSubmission.where(
        user: current_user,
        course_project_version: @course_project_version,
      )]
    )

    # FIXME!! authorize the right thing
    authorize @project_submission || @course_project_version

    # TODO: only return the latest for each input_name.
  end

  def create
    # FIXME!! authorize the right thing
    authorize @course_project_version

    ProjectSubmissionAnswer.transaction do
      ProjectSubmissionAnswer.create_or_update_by!(
        project_submission: ProjectSubmission.create_or_find_by!(
          user: current_user,
          course_project_version: @course_project_version,
          is_submitted: false,
        ),
        input_name: create_params[:input_name],
        input_value: create_params[:input_value],
      )
    end
  end

private

  def create_params
    params.require(:project_submission_answer).permit(:input_name, :input_value)
  end
end
