require 'rest-client'
require 'lti_deep_linking_request_message'
require 'lti_resource_link_request_message'

# Helps parse and valid an LTI extension id_token sent in the authentication response
# of an LTI Launch.
# See: 
# - https://medium.com/@darutk/understanding-id-token-5f83f50fa02e
# - https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#launch-overview
# - http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation
class LtiIdToken

  # The URL of the Public JWK used to sign payloads sent from Canvas so that we can
  # verify it was actually Canvas sending the payload and not an attacker.
  PUBLIC_JWKS_URL = "#{Rails.application.secrets.lti_oidc_base_uri}/api/lti/security/jwks".freeze

  MESSAGE_TYPE_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/message_type'.freeze
  MESSAGE_TYPE_TO_CLASS = { 
    'LtiResourceLinkRequest' => LtiResourceLinkRequestMessage,
    'LtiDeepLinkingRequest' => LtiDeepLinkingRequestMessage 
  }

  # Takes a signed JWT id_token (base64encoded) and parses the contents out while
  # verifying the signature so that we know it was actually sent by the LTI platform
  #
  # Returns an instance of the class that handles the type of message in the payload.
  def self.parse_and_verify(signed_jwt_id_token)
    payload, header = JWT.decode(signed_jwt_id_token, nil, true, { algorithms: ['RS256'], jwks: public_jwks } )
    message_type = payload[MESSAGE_TYPE_CLAIM]
    MESSAGE_TYPE_TO_CLASS[message_type].new(payload)
  rescue => e
    Rails.logger.error("{\"Error\":\"#{e.message}\"}")
    Rails.logger.error(e.response.body) if e.is_a?(RestClient::Exception)
    raise
  end

  def self.public_jwks
    Honeycomb.start_span(name: 'LtiIdToken.public_jwks') do |span|
      span.add_field('url', PUBLIC_JWKS_URL)
      response = RestClient.get(PUBLIC_JWKS_URL)
      JSON.parse(response.body, symbolize_names: true)
    end
  end
  private_class_method :public_jwks

end

