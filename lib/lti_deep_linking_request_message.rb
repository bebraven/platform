require 'lti_launch_request_message'

# Represents an LTI Deep Linking Request message as specified here:
# https://www.imsglobal.org/spec/lti-dl/v2p0#deep-linking-request-message
#
# An example of this message being sent is when a Designer goes to add an
# External Tool to a module or to an assignment.
class LtiDeepLinkingRequestMessage < LtiLaunchRequestMessage
  attr_reader :deep_link_return_url

  DEEP_LINKING_SETTINGS_CLAIM = 'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'.freeze

  def initialize(payload)
    super(payload)
    @deep_link_return_url = payload.fetch(DEEP_LINKING_SETTINGS_CLAIM)['deep_link_return_url']
  end

end
