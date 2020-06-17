class LtiPocController < ApplicationController

  # TODO: tmp for testing. We need to get auth actually working.
  skip_before_action :authenticate_user!
  skip_before_action :ensure_admin!

  skip_before_action :verify_authenticity_token

  def index
    # TODO: complete hackery. Clean this up to whitelist braven cloud for all LTI related controllers.
    response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM https://braven.instructure.com"
    @canvas_user_id = Rails.cache.fetch("canvas_user_id")
    @canvas_email = Rails.cache.fetch("canvas_email")
    @canvas_fullname = Rails.cache.fetch("canvas_fullname")
    @canvas_course_name = Rails.cache.fetch("canvas_course_name")
    puts "### in lti_editor: canvas_user_id = #{@canvas_user_id}, @canvas_email = #{@canvas_email}, @canvas_fullname = #{@canvas_fullname}, @canvas_course_name = #{@canvas_course_name}"

    @deep_link_return_url = Rails.cache.fetch("lti_deep_link_return_url")
    puts "### Set @deep_link_return_url = #{@deep_link_return_url}"
    @jwt_response =  Rails.cache.fetch("lti_deep_link_jwt_response")
    puts "### @jwt_response = #{@jwt_response}"
  end

  def create
    redirect_to lti_lti_poc_index_path
  end

end
