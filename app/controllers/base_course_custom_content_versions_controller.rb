# frozen_string_literal: true

class BaseCourseCustomContentVersionsController < ApplicationController
  include DryCrud::Controllers::Nestable
  include LtiHelper

  layout 'lti_placement'

  nested_resource_of BaseCourse

  before_action :set_custom_content, only: [:create]
  before_action :set_base_course # TODO: shouldn't DryCrud handle this?

  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

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

    # If we end up adding a designer role, remember to authorize `ProjectVersion.create?`.
    authorize BaseCourseCustomContentVersion

    raise NotImplementedError, "TODO: save a new custom_content_version and create a new BaseCourseCustomContentVersion with it mapping it to this BaseCourse[#{@base_course.inspect}]"
   
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

end
