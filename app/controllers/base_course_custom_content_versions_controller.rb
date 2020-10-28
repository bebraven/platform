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
    @projects = Project.all
  end

  # Create a Project for an LTI assignment placement
  def create

    # If we end up adding a designer role, remember to authorize `ProjectVersion.create?`.
    authorize BaseCourseCustomContentVersion

    raise NotImplementedError, "TODO: save a new custom_content_version and create a new BaseCourseCustomContentVersion with it mapping it to this BaseCourse[#{@base_course.inspect}]"

#    # Create new version of the content
#    @custom_content.save_version!(current_user)
#
#    ca = CanvasAPI.client.create_assignment(@base_course.canvas_course_id)
#
#    # Create join table entry
#    @course_content_version = BaseCourseCustomContentVersion.create!(
#      base_course: @base_course,
#      custom_content_version: @custom_content.last_version,
#      canvas_assignment_id: ca['id']
#    )
#
## TODO: reimplement me to programmatically create the Canvas Assignment using the Canvas API and
## then linking it to the LTI content below using the Line Items API.
##    # Create a submission URL for this course and version
##    submission_url = new_base_course_custom_content_version_project_submission_url(
##      base_course_custom_content_version_id: @course_content_version.id,
##    )
##    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(@lti_launch, submission_url)
    
  end

  # Update a Project for an LTI assignment placement with latest version
  def update
    authorize @base_course_custom_content_version
    raise NotImplementedError, "TODO: save a new custom_content_version and update this BaseCourseCustomContentVersion[#{@base_course_custom_content_version.inspect}] with it"

#    new_custom_content_version = @base_course_custom_content_version.custom_content.save_version!(current_user)
## TODO: don't think we need to adjust canvas URL b/c we're just updating this record with a new custom content version...
##    ca = CanvasAPI.client.get_assignment(@base_course.canvas_course_id, @base_course_custom_content_version.canvas_assignment_id)
#    @base_course_custom_content_version.custom_content_version = new_custom_content_version
#    @base_course_custom_content_version.save!
  end

  def destroy
    authorize @base_course_custom_content_version
    raise NotImplementedError, "TODO: delete the local BaseCourseCustomContentVersion[#{@base_course_custom_content_version.inspect}] and call into Canvas to delete the associated assignment"
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
