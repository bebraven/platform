require "lrs_xapi_proxy"

class LrsXapiProxyController < ApplicationController
  skip_before_action :verify_authenticity_token
  wrap_parameters false # Disable putting everything inside a "lrs_xapi_proxy" param. This controller doesn't represent a model.

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  def xAPI
    # TODO: Make sure current_user is allowed to view user_override's stuff.
    # https://app.asana.com/0/1174274412967132/1185569091008475/f
    #
    # A user_override is used when say a Teaching Assistant is viewing a project
    # submission for a Student/Fellow. The current_user would be the TA but we really
    # want to be querying the LRS as the Student.
    user = params[:user_override_id] ? User.find(params[:user_override_id]) : current_user

    # Only allow if `current_user` should have access to `user`'s data.
    if request.method == 'GET'
      authorize user, :xAPI_read?, policy_class: LrsXapiProxyPolicy
    else
      authorize user, :xAPI_write?, policy_class: LrsXapiProxyPolicy
    end

    response = LrsXapiProxy.request(request, request.params['endpoint'], user)
    response_body = response.body
    if response_body
      content_type = response.headers[:content_type]
      # Note: have to be explicit with the content type here b/c it may "look" like json (and is) sometimes but
      # the Rise360 package PUT/GET's it as plain data and fails if we say it's json. I'm at a loss as to why.
      render plain: response_body, status: response.code, content_type: content_type and return if content_type == LrsXapiProxy::OCTET_STREAM_MIME_TYPE
      render json: response_body, status: response.code and return if content_type == LrsXapiProxy::JSON_MIME_TYPE
    end
  rescue RestClient::Exception => e
    render json: e.http_body.to_json, status: e.http_code
  end
end
