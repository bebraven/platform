require 'lti_deep_linking_response_message'
require 'lti_deep_linking_request_message'

module LtiHelper

  def lti_deep_link_response_message(lti_launch, content_items_url)
    client_id = lti_launch.auth_params[:client_id]
    deep_link = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload)
    response_msg = LtiDeepLinkingResponseMessage.new(client_id, deep_link.deployment_id)
    response_msg.addIFrame(content_items_url)
    jwt_response = Keypair.jwt_encode(response_msg.to_h)

    [deep_link.deep_link_return_url, jwt_response]
  end

  def set_lti_launch
    return if @lti_launch
    @lti_launch = LtiLaunch.current(params[:state]) if params[:state]
  end

  def is_sessionless_lti_launch?
    set_lti_launch
    (@lti_launch ? @lti_launch.sessionless? : false )
  end
end
