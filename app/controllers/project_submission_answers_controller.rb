
class ProjectSubmissionAnswersController < ApplicationController
  include DryCrud::Controllers::Nestable

  nested_resource_of CourseProjectVersion

  def index
    @project_submission_answers = ProjectSubmissionAnswer.where(
      project_submission: [ProjectSubmission.where(
        user: current_user,
        course_project_version: @course_project_version,
      )],
    )
    # FIXME!! authorize the right thing
    authorize @course_project_version

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
