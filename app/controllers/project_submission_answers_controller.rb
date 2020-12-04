
class ProjectSubmissionAnswersController < ApplicationController
  include DryCrud::Controllers::Nestable

  nested_resource_of CourseProjectVersion

  def create
    # FIXME!! authorize the right thing
    authorize @course_project_version

    ProjectSubmissionAnswer.update_or_create_by!(
      project_submission: ProjectSubmission.find_or_create_by!(
        user: current_user,
        course_project_version: @course_project_version,
        is_submitted: false,
      ),
      input_name: create_params[:input_name],
      input_value: create_params[:input_value],
    )
  end

private

  def create_params
    params.require(:project_submission_answer).permit(:input_name, :input_value)
  end
end
