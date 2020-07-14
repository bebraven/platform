# Base class for common logic shared between any type of LTI Launch. E.g.
# an LtiResourceLinkRequest or LtiDeepLinkingRequest 
class LtiLaunchRequestMessage
  attr_reader :payload, :deployment_id, :target_link_uri

  TARGET_LINK_URI_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/target_link_uri'.freeze
  DEPLOYMENT_ID_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/deployment_id'.freeze

  def initialize(payload)
    @payload = payload
    @deployment_id = payload.fetch(DEPLOYMENT_ID_CLAIM)
    @target_link_uri = payload.fetch(TARGET_LINK_URI_CLAIM)
  end

end
