require 'lti_id_token'

# Stores info about an LTI launch so we can access that stuff in future calls
# in the context of that launch. See this for details about the LTI launch flow
# https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#launch-overview
class LtiLaunch < ApplicationRecord
  serialize :id_token_payload, JSON

  # This is the Redirect URI that must be configured in the Developer Key for the LTI
  # and must match EXACTLY.
  LTI_LAUNCH_REDIRECT_URI="https://#{Rails.application.secrets.application_host}/lti/launch".freeze

  scope :authenticated, -> { where.not id_token_payload: nil }
  scope :unauthenticated, -> { where id_token_payload: nil }

  # The fully authenticated LtiLaunch for this state (aka launch session)
  def self.current(state)
    launch = LtiLaunch.where(state: state).authenticated.first!
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

