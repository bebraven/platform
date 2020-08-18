require 'lti_id_token'

# Stores info about an LTI launch so we can access that stuff in future calls
# in the context of that launch. See this for details about the LTI launch flow
# https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#launch-overview
class LtiLaunch < ApplicationRecord
  serialize :id_token_payload, JSON

  # This is the Redirect URI that must be configured in the Developer Key for the LTI
  # and must match EXACTLY.
  LTI_LAUNCH_REDIRECT_URI="https://#{Rails.application.secrets.application_host}/lti/launch".freeze
  BRAVEN_ISS="https://#{Rails.application.secrets.application_host}".freeze

  scope :authenticated, -> { where.not id_token_payload: nil }
  scope :unauthenticated, -> { where id_token_payload: nil }

  # The fully authenticated LtiLaunch for this state (aka launch session)
  def self.current(state)
    launch = LtiLaunch.where(state: state).authenticated.first!
  end

  # Alias for current but returns false if there is no authenticated LtiLaunch for this "state"
  def self.is_valid?(state)
     # TODO: need to expire launches. They shouldn't be valid forever. Maybe only 2 weeks.
     # Actually, we should just clear out launch records from the database periodically,
     # whatever the valid length of time we choose. No reason for the launches table to grow
     # forever. The state parameters are sent in the iframed URL and authentication header so
     # an attacker could theoretically brute force a login, which makes it more important to
     # to not have them valid forever.
     # Task: https://app.asana.com/0/1174274412967132/1184057808812020
     ll = LtiLaunch.where(state: state).authenticated.first
     (ll.present? ? ll : false)
  end

  # Authenticates an LtiLaunch with the id_token sent from the platform
  def self.authenticate(state, id_token)
    idt = LtiIdToken.parse_and_verify(id_token)
    launch = LtiLaunch.find_by!(state: state)
    launch.id_token_payload = idt.payload

    # The initial target uri in the login doesn't always match the actual target in the payload so update it. E.g. assignment selection
    launch.target_link_uri = idt.target_link_uri

    # TODO: hitting the back button seems to make Canvas do the launch again. You have to hit back twice.
    # There may be another solution, like the redirect needs to be done differently from launch to target link uri,
    # but another solution would be to clear the nonce on the authenticate and if the nonce is missing then redirect
    # back to canvas ourselves.

    launch.save!
    launch
  end

  # Returns the parse request message payload of the launch
  def request_message
    @request_message ||= LtiIdToken.parse(id_token_payload)
  end

  # The user that this launch is for.
  def user
    User.find_by_canvas_id(request_message.canvas_user_id)
  end

  # Each lesson or project has a single activity ID that ties together all the xAPI statements
  # for it. This returns that ID.
  def activity_id
    raise ArgumentError.new, 'Wrong LTI launch message type. Must be a launch of a ResourceLink.' unless request_message.is_a?(LtiResourceLinkRequestMessage) 

    # Note:  request_message.resource_link['id'] is an LTI ID tied to this resource, but activity_id 
    # can't be a GUID, it has to be a URI per the xAPI specs. That's the point of this.
    aid = Integer(request_message.custom['assignment_id']) # raises ArgumentError if not an int
    cid = Integer(request_message.custom['course_id'])    # ditto
    "#{Rails.application.secrets.canvas_cloud_url}/courses/#{cid}/assignments/#{aid}"
  end

  # True if this is an LtiLaunch that doesn't have access to normal Devise session based authentication
  # and needs to use the "state" parameter as the effective authentication token.
  def sessionless?
    !!sessionless
  end

  # Returns a unique identifier for us when issuing and JWT
  def braven_iss
    BRAVEN_ISS
  end

  # Returns the parameters needed in Step 2 of the LTI Launch flow in order
  # to do the handshake with the LTI platform (aka Canvas) and "login" / authenitcate
  # an LTI launch / session. See: 
  # http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request
  def auth_params
    {
      :scope => 'openid',                    # OIDC Scope
      :response_type => 'id_token',          # OIDC response is always an id token
      :response_mode => 'form_post',         # OIDC response is always a form post
      :prompt => 'none',                     # Don't prompt user on redirect
      :client_id => client_id,
      :redirect_uri => LTI_LAUNCH_REDIRECT_URI,  # URL to return to after login
      :state => state,                       # State to identify the launch session. Note: may be multiple per browser session
      :nonce => nonce,                       # Prevent replay attacks 
      :login_hint =>  login_hint,            # Login hint to identify platform (aka Canvas) session
      :lti_message_hint => lti_message_hint  # Used by platform (aka Canvas) to store / identify context on their end. Opaque to us.
    }
  end
end

