require 'zip'

class Rise360ModulesController < ApplicationController
  include LtiHelper
  layout 'lti_canvas'

  before_action :set_lti_launch, only: [:create, :show]
  skip_before_action :verify_authenticity_token, only: [:create, :show], if: :is_sessionless_lti_launch?

  def new
    authorize @rise360_module
  end

  def create
    authorize Rise360Module
    @rise360_module = Rise360Module.create!(rise360_zipfile: create_params[:rise360_zipfile])
    @deep_link_return_url, @jwt_response = helpers.lti_deep_link_response_message(@lti_launch, rise360_module_url(@rise360_module))
  end

  def show
    authorize @rise360_module
    # TODO: this may be while previewing the the Lesson before inserting it through the
    # assignment selection placement. Don't configure it to talk to the LRS in that case.
    # https://app.asana.com/0/search/1189124318759625/1187445581799823
    url = Addressable::URI.parse(@rise360_module.launch_url)
    url.query_values = helpers.launch_query
    redirect_to url.to_s
  end

private
  def create_params
    params.require([:state, :rise360_zipfile])
    params.permit(:rise360_zipfile, :state, :commit, :authenticity_token)
  end

end
