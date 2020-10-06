class CourseResourcesController < ApplicationController

  include LtiHelper

  before_action :set_lti_launch, only: [:lti_show]

  def new
    authorize @course_resource
  end

  def create
    authorize CourseResource
    @course_resource = CourseResource.create!(name: create_params[:name], course_resource_zipfile: create_params[:course_resource_zipfile])
    redirect_to base_courses_path, notice: 'Course resource was successfully created.'
  end

  def lti_show
    authorize CourseResource
    canvas_course_id = @lti_launch.request_message.custom['course_id']
    base_course = BaseCourse.find_by(canvas_course_id: canvas_course_id)
    if base_course&.course_resource
      url = Addressable::URI.parse(base_course.course_resource.launch_url)
      url.query_values = helpers.launch_query
      redirect_to url.to_s
    else
      render plain: "Course resources not configured!", status: 404
    end
  end

  private
  def create_params
    params.require([:course_resource_zipfile])
    params.permit(:name, :course_resource_zipfile, :commit, :authenticity_token)
  end

end
