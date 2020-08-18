require 'zip'

class LessonContentsController < ApplicationController
  include LtiHelper
  layout 'lti_placement'

  before_action :set_lti_launch, only: [:create, :show]
  skip_before_action :verify_authenticity_token, only: [:create, :show], if: :is_sessionless_lti_launch?

  def new
  end

  def create
    @lesson_content = LessonContent.create!(lesson_content_zipfile: create_params[:lesson_content_zipfile])
    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(@lti_launch, lesson_content_url(@lesson_content))
  end

  def show
    # TODO: this may be while previewing the the Lesson before inserting it through the
    # assignment selection placement. Don't configure it to talk to the LRS in that case.
    # https://app.asana.com/0/search/1189124318759625/1187445581799823
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
