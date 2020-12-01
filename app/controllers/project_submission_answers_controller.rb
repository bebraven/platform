
class ProjectSubmissionAnswersController < ApplicationController
  def create
    ProjectSubmissionAnswer.update_or_create_by!(
      user: current_user,
      base_course_custom_content_version_id: params[:base_course_custom_content_version_id],
      input_name: params[:input_name],
      input_value: params[:input_value],
    )
  end
end
