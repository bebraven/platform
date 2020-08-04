require 'zip'

class LessonContentsController < ApplicationController
  layout 'lti_placement'

  def new
  end

  def create
    lti_launch = LtiLaunch.current(create_params[:state])

    @lesson_content = LessonContent.create!(lesson_content_zipfile: create_params[:lesson_content_zipfile])

    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(lti_launch, lesson_content_url(@lesson_content))
  end

  def show
    url = Addressable::URI.parse(@lesson_content.launch_url)
    url.query_values = helpers.launch_query
    redirect_to url.to_s
  end

  private
  def create_params
    params.require([:state, :lesson_content_zipfile])
    params.permit(:lesson_content_zipfile, :state, :commit, :authenticity_token)
  end
end
