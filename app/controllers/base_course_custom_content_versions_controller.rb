# frozen_string_literal: true

class BaseCourseCustomContentVersionsController < ApplicationController
  include DryCrud::Controllers::Nestable
  include LtiHelper

  layout 'lti_placement'

  before_action :set_lti_launch, only: [:create]
  before_action :set_custom_content, only: [:create]
  before_action :set_base_course, only: [:create]

  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  # Create a Project for an LTI assignment placement
  def create
    # If we end up adding a designer role, remember to authorize `ProjectVersion.create?`.
    authorize BaseCourseCustomContentVersion
    # Create new version of the content
    @custom_content.save_version!(current_user)

    # Create join table entry
    @course_content_version = BaseCourseCustomContentVersion.create!(
      base_course: @base_course,
      custom_content_version: @custom_content.last_version,
    )

    # Create a submission URL for this course and version
    submission_url = new_base_course_custom_content_version_project_submission_url(
      base_course_custom_content_version_id: @course_content_version.id,
    )
    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(@lti_launch, submission_url)
  end

  private
  def set_custom_content
    params.require(:custom_content_id)
    @custom_content = CustomContent.find(params[:custom_content_id])
  end

  def set_base_course
    @base_course = BaseCourse.find_by!(
      canvas_course_id: @lti_launch.request_message.custom['course_id'],
    )
  end
end
