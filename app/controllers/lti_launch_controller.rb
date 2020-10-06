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
  skip_before_action :verify_authenticity_token

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  LTI_ISS=Rails.application.secrets.lti_oidc_base_uri
  LTI_AUTH_RESPONSE_URL="#{Rails.application.secrets.lti_oidc_base_uri}/api/lti/authorize_redirect".freeze

  # POST /lti/login
  #
  # This is the OIDC url Canvas is calling in Step 1 above.
  def login
    authorize LtiLaunch
    raise ActionController::BadRequest.new(), "Unexpected iss parameter: #{params[:iss]}" if params[:iss] != LTI_ISS

    @lti_launch = LtiLaunch.create!(params.except(:iss, :canvas_region).permit(:client_id, :login_hint, :target_link_uri, :lti_message_hint)
                                         .merge(:state => LtiLaunchController.generate_state, :nonce => SecureRandom.hex(10)))

    # Step 2 in the flow, do the handshake
    redirect_to "#{LTI_AUTH_RESPONSE_URL}?#{@lti_launch.auth_params.to_query}"
  end


  # POST /lti/launch
  #
  # This is the endpoint configured as the Redirect URI in the Canvas Developer Key. It's Step 3 in the launch flow.
  def launch
    params.require([:id_token, :state])

    # This also verifies the request is coming from Canvas using the public JWK 
    # as described in Step 3 here: https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    ll = LtiLaunch.authenticate(params[:state], params[:id_token])

    # Sign in the user on Platform. Note that if third party cookies aren't allowed in the
    # browser this will have no effect and the LtiAuthentication::WardenStrategy will be used
    # for each request to authenticate them instead of using session.
    sign_in_from_lti(ll)

    authorize ll

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

  # Generates a globally unique value to use in the "state" parameter of an LTI Launch. This uniquely identifies
  # an authenticated session so it must be long enough to prevent brute force attacks.
  def self.generate_state
    "#{Base64.urlsafe_encode64(SecureRandom.uuid)}#{SecureRandom.urlsafe_base64(96)}" # 32+96=128 chars
  end

  private

  # Grab the user ID out of the payload and tell devise that they are authenticated for this session.
  def sign_in_from_lti(ll)
    if user = ll.user 
      sign_in user
      Rails.logger.debug("Done signing in LTI-authenticated user #{user.email}")
    else
      Rails.logger.debug("Invalid user came through LTI launch: #{ll.request_message.inspect}")
    end
  end

end
