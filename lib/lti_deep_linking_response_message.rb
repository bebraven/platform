# Represents an LTI Deep Linking Response message as specified here:
# https://www.imsglobal.org/spec/lti-dl/v2p0#deep-linking-response-message
#
# An example of this message being sent is after a Designer chooses to add an
# External Tool to a module or to an assignment and selects the resource to add.
# This tells the platform (aka Canvas) what should be launched when a Student 
# clicks on it.
class LtiDeepLinkingResponseMessage

  def initialize(client_id, deployment_id)
    @client_id = client_id
    @deployment_id = deployment_id
    @content_items = []
  end

  def to_h
    {
      iss: @client_id, # A unique identifier for the entity that issued the JWT
      aud: Rails.application.secrets.lti_oidc_base_uri, # Authorization server identifier
      iat: Time.now.to_i, # Timestamp for when the JWT was created
      exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
      # (after allowing a margin for clock skew)
      azp: @client_id,
      nonce: SecureRandom.hex(10),
      "https://purl.imsglobal.org/spec/lti/claim/message_type" => "LtiDeepLinkingResponse",
      "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
      "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => @deployment_id,
      "https://purl.imsglobal.org/spec/lti-dl/claim/content_items" => @content_items
    }
  end 

  def addIFrame(url)
    # Note: Canvas ignores the width and height options for iframe if they were specified. We always get 100% of available space.
    @content_items << { "type" => "ltiResourceLink", "url" => url, "iframe" => { } }
  end
end
