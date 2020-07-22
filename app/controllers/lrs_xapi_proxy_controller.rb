require "lrs_xapi_proxy"

class LrsXapiProxyController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  def xAPI
    response = LrsXapiProxy.request(request, request.params['endpoint'], current_user)
    render json: response.body, status: response.code
  end
  
end
