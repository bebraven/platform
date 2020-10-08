class CustomContentVersionsController < ApplicationController
  include LtiHelper
  include DryCrud::Controllers::Nestable

  nested_resource_of CustomContent
  layout 'content_editor'

  before_action :set_lti_launch, only: [:show]

  # GET /custom_contents/:id/versions
  # GET /custom_contents/:id/versions.json
  def index
    authorize CustomContentVersion
  end

  # GET /custom_contents/:id/versions/1
  # GET /custom_contents/:id/versions/1.json
  def show
    authorize @custom_content_version
  end
end
