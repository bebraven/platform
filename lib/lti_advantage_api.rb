# frozen_string_literal: true
require 'rest-client'
require 'lti_resource_link_request_message'

# Helps access the LTI Advatange services described in the following links. These
# services are mostly used for passing grade data back to Canvas from our LTI extension.
# Note: these are only available for LTI resources added using the Assignment Selection
# placement. See the notes under "Limitations" here: https://canvas.instructure.com/doc/api/file.link_selection_placement.html
#
# See: 
# - https://www.imsglobal.org/spec/lti-ags/v2p0/#introduction
# - https://canvas.instructure.com/doc/api/line_items.html
# - https://canvas.instructure.com/doc/api/score.html
#
# - For OAuth stuff to get an access token, see:
# - https://canvas.instructure.com/doc/api/file.oauth.html#accessing-lti-advantage-services
# - https://www.imsglobal.org/spec/security/v1p0/#using-oauth-2-0-client-credentials-grant
class LtiAdvantageAPI

  OAUTH_ACCESS_TOKEN_URL = "#{Rails.application.secrets.canvas_cloud_url}/login/oauth2/token"
  JSON_HEADERS = {content_type: :json, accept: :json}

  # The assignment_lti_launch should be an LtiLaunch of an already Deep Linked assignment
  # created using the Assignment Selection Placement.
  def initialize(assignment_lti_launch)
    validate_param(assignment_lti_launch)

    @iss = assignment_lti_launch.braven_iss
    @client_id = assignment_lti_launch.client_id 
    @scope = parse_scope(assignment_lti_launch)
    @line_items_url = assignment_lti_launch.request_message.line_items_url
    @line_item_url = assignment_lti_launch.request_message.line_item_url
    @global_headers = JSON_HEADERS # get_access_token below needs this initialized
    @global_headers = @global_headers.merge(:Authorization => "Bearer #{get_access_token}") # Note: these expire about about an hour.
  end

  # Sends a score / grade for this LTI resource (aka a Project or a Lesson) back
  # to Canvas so it shows up in the gradebook. See: https://canvas.instructure.com/doc/api/score.html
  #
  # Usage:
  # LtiAdvantageAPI.new(<the_launch>).create_score( LtiScore.generate(...) ) 
  def create_score(lti_score)
    response = post("#{@line_item_url}/scores", lti_score)
    JSON.parse(response.body)
  end

  def get_line_item_for_user(canvas_user_id)
    response = get("#{@line_item_url}/results?user_id=#{canvas_user_id}")
    JSON.parse(response.body)
  end

  # Gets a list of line items, aka columns, in the gradebook for this LTI launch context (aka the course)
  # that scores can be sent to.
  # See: https://canvas.instructure.com/doc/api/line_items.html
  def get_line_items
    response = get(@line_items_url)
    JSON.parse(response.body)
  end

private

  def get_access_token
    response = post(OAUTH_ACCESS_TOKEN_URL, client_credentials_grant_message)
    JSON.parse(response.body)['access_token']
  end

  # See "Examples using client_credentials" here:
  #  https://canvas.instructure.com/doc/api/file.oauth_endpoints.html#post-login-oauth2-token
  def client_credentials_grant_message
    {
      :grant_type => 'client_credentials',
      :client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      :client_assertion => Keypair.jwt_encode(bearer_token_payload),
      :scope => @scope
    }.to_json
  end

  # Payload of JWT used as Bearer token authenticating this server as being allowed to 
  # request an OAuth access token. 
  # See: https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant
  def bearer_token_payload
    {
      iss: @iss,                         # A unique identifier for the entity that issued the JWT
      aud: OAUTH_ACCESS_TOKEN_URL,       # Authorization server identifier
      iat: Time.now.to_i,                # Timestamp for when the JWT was created
      exp: Time.now.to_i + 300,          # Timestamp for when the JWT should be treated as having expired
      sub: @client_id,                   # Client ID of Developer Key configured in Canvas.
      jti: SecureRandom.uuid             # Unique ID for this JWT
    }
  end

  def validate_param(assignment_lti_launch)
    req_msg = assignment_lti_launch.request_message
    raise ArgumentError.new, 'Wrong LTI launch message type. Must be a launch of a resource.' unless req_msg.is_a?(LtiResourceLinkRequestMessage) 
    raise ArgumentError.new, 'Missing scope. Needed to get an access token for LTI Advantage access' unless req_msg.scope.present?
    raise ArgumentError.new, 'Missing lineitem. Needed to send a score back for this resource.' unless req_msg.line_item_url.present?
  end

  # Parses the scope array out of the launch message into the space delimited list expected in the access token grant message.
  def parse_scope(assignment_lti_launch)
    assignment_lti_launch.request_message.scope.join(' ')
  end

  def get(target_url, headers={})
    RestClient.get(target_url, @global_headers.merge(headers))
  end

  def post(target_url, body, headers={})
    RestClient.post(target_url, body, @global_headers.merge(headers))
  end

end

