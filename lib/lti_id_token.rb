require 'rest-client'

# Helps parse and valid an LTI extension id_token sent in the authentication response
# of an LTI Launch.
# See: 
# - https://medium.com/@darutk/understanding-id-token-5f83f50fa02e
# - https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#launch-overview
# - http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation
class LtiIdToken
  attr_reader :header, :payload

  # The URL of the Public JWK used to sign payloads sent from Canvas so that we can
  # verify it was actually Canvas sending the payload and not an attacker.
  PUBLIC_JWKS_URL = "#{Rails.application.secrets.lti_oidc_base_uri}/api/lti/security/jwks".freeze

  def initialize(payload, header)
    @header = header
    @payload = payload
  end

  # Takes a signed JWT id_token (base64encoded) and parses the contents out while
  # verifying the signature so that we know it was actually sent by the LTI platform
  def self.parse_and_verify(signed_jwt_id_token)
    payload, header = JWT.decode(signed_jwt_id_token, nil, true, { algorithms: ['RS256'], jwks: public_jwks } )
    LtiIdToken.new(payload, header)
  rescue => e
    Rails.logger.error("{\"Error\":\"#{e.message}\"}")
    Rails.logger.error(e.response.body)
    raise
  end

  private

  def self.public_jwks
    response = RestClient.get(PUBLIC_JWKS_URL)
    JSON.parse(response.body, symbolize_names: true)
  end
end

