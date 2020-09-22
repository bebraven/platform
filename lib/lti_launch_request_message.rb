# Base class for common logic shared between any type of LTI Launch. E.g.
# an LtiResourceLinkRequest or LtiDeepLinkingRequest 
class LtiLaunchRequestMessage
  attr_reader :message_type, :payload, :deployment_id, :target_link_uri, :canvas_user_id, :canvas_course_id, :custom

  TARGET_LINK_URI_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/target_link_uri'.freeze
  DEPLOYMENT_ID_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/deployment_id'.freeze
  MESSAGE_TYPE_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/message_type'.freeze
  CUSTOM_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/custom'.freeze

  def initialize(payload)
    @payload = payload
    @custom = payload.fetch(CUSTOM_CLAIM)
    @message_type = payload.fetch(MESSAGE_TYPE_CLAIM)
    @deployment_id = payload.fetch(DEPLOYMENT_ID_CLAIM)
    @target_link_uri = payload.fetch(TARGET_LINK_URI_CLAIM)
    @canvas_user_id = custom['user_id']
    @canvas_course_id = custom['course_id']
  end

end
