
# Implement the LTI 1.3 Launch Flow. Here is a nice summary of that flow by Canvas, our LMS:
# https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#launch-overview
#
# Summary of flow:
# Step 1: Login Initiation - Canvas calls into here letting us know a launch is starting
# Step 2: Authentication Response - We initiate an handshake to authenticate the launch establish a trust in the launch
# Step 3: LTI Launch - The launch is initated with meta-data about the context and the final target resource to launch
# Step 4: Resource Display - We display the target resource
class LtiLaunchController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_admin!
  skip_before_action :verify_authenticity_token

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  LTI_ISS=Rails.application.secrets.lti_oidc_base_uri
  LTI_AUTH_RESPONSE_URL="#{Rails.application.secrets.lti_oidc_base_uri}/api/lti/authorize_redirect".freeze

  # POST /lti/login
  #
  # This is the OIDC url Canvas is calling in Step 1 above.
  def login
    raise ActionController::BadRequest.new(), "Unexpected iss parameter: #{params[:iss]}" if params[:iss] != LTI_ISS

   # TODO: this table is going to blow up in size. We should grab existing launches that match this resource but are older and
   # replace it OR write a cronjob to clear out old ones. Though we probably do want historical data on engagement and what is being launched,
   # and by who so take that into consideration.
    @lti_launch = LtiLaunch.create!(params.except(:iss, :canvas_region).permit(:client_id, :login_hint, :target_link_uri, :lti_message_hint)
                                         .merge(:state => SecureRandom.uuid, :nonce => SecureRandom.hex(10)))

    # Step 2 in the flow, do the handshake
    redirect_to "#{LTI_AUTH_RESPONSE_URL}?#{@lti_launch.auth_params.to_query}"
  end


  # POST /lti/launch
  #
  # This is the endpoint configured as the Redirect URI in the Canvas Developer Key. It's Step 3 in the launch flow.
  def launch
    params.require([:id_token, :state])

    # TODO: also grab the user email out of the payload and tell devise that they are authenticated for this session

    # This also verifies the request is coming from Canvas using the public JWK 
    # as described in Step 3 here: https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    ll = LtiLaunch.authenticate(params[:state], params[:id_token])

    # Step 4 in the flow, show the target resource now that we've saved the id_token payload that contains
    # user identifiers, course contextual data, custom data, etc.
    target_uri_with_params = URI(ll.target_link_uri)
    if target_uri_with_params.query
      target_uri_with_params.query += "&state=#{params[:state]}"
    else
      target_uri_with_params.query = "state=#{params[:state]}"
    end
    redirect_to target_uri_with_params.to_s
  end
end
