# frozen_string_literal: true

class BaseCourseCustomContentVersionsController < ApplicationController
  include DryCrud::Controllers::Nestable
  include LtiHelper

  layout 'lti_placement'

  nested_resource_of BaseCourse

  before_action :set_custom_content, only: [:create]
  before_action :set_base_course, except: [:create] # TODO: shouldn't DryCrud handle this?

  # TODO: get rid of these when we refactor to be run from Course Mgmt page.
  before_action :set_lti_launch, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?
  before_action :set_base_course_from_lti_launch, only: [:create]

  # Show form to select new Project to create as an LTI linked Canvas assignment
  def new
    # If we end up adding a designer role, remember to authorize `ProjectVersion.create?`.
    authorize @base_course_custom_content_version

    # TODO: exclude those already on this BaseCourse.
    # https://app.asana.com/0/1174274412967132/1198965066699369
    @projects = Project.all
  end

  # Create a Project for an LTI assignment placement
  def create

    # TODO: refactor this to be run from the Course Mgmt page. Create a new assignment 
    # in Canvas through the API, save a new custom_content_version and create a new 
    # BaseCourseCustomContentVersion with it mapping this base course to the new canvas assignment
    # and content version

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

  # Publish the latest Project, Survey, etc (aka CustomContent) so that the Canvas assignment this
  # BaseCourseCustomContentVersion represents shows the latest content.
  def update
    authorize @base_course_custom_content_version

    raise NotImplementedError, "TODO: save a new custom_content_version from the latest and re-associated this BaseCourseCustomContentVersion[#{@base_course_custom_content_version.inspect}] with it. Canvas assignment doesn't need to change."
  end

  # Deletes a Project, Survey, etc (aka CustomContent) from the Canvas course that this
  # BaseCourseCustomContentVersion join model represents and then deletes this record locally.
  def destroy
    authorize @base_course_custom_content_version

    raise NotImplementedError, "TODO: delete both the Canvas assignment and this BaseCourseCustomContentVersion[#{@base_course_custom_content_version.inspect}]"

  end

  private
  def set_custom_content
    params.require(:custom_content_id)
    @custom_content = CustomContent.find(params[:custom_content_id])
  end

  def set_base_course
    @base_course = BaseCourse.find(params.require(:base_course_id))
    @base_course.verify_can_edit!
  end

 def set_base_course_from_lti_launch
    @base_course = BaseCourse.find_by!(
      canvas_course_id: @lti_launch.request_message.custom['course_id'],
    )
  end
end
