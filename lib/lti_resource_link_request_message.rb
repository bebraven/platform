require 'lti_launch_request_message'

# Represents an LTI Resource Link launch request message as specified here:
# https://www.imsglobal.org/spec/lti/v1p3#launch-from-a-resource-link-0
#
# An example of this message being sent is when a Student clicks on an
# item in a module that was added as an External Tool
class LtiResourceLinkRequestMessage < LtiLaunchRequestMessage 
  attr_reader :resource_link

  RESOURCE_LINK_CLAIM = 'https://purl.imsglobal.org/spec/lti/claim/resource_link'.freeze

  def initialize(payload)
    super(payload)
    @resource_link = payload.fetch(RESOURCE_LINK_CLAIM)['id']
  end

end
