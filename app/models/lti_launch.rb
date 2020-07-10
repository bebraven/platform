# Stores info about an LTI launch so we can access that stuff in future calls
# in the context of that launch. See this for details about the LTI launch flow
# https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#launch-overview
class LtiLaunch < ApplicationRecord

  # This is the Redirect URI that must be configured in the Developer Key for the LTI
  # and must match EXACTLY.
  LTI_LAUNCH_REDIRECT_URI="https://#{Rails.application.secrets.application_host}/lti/launch".freeze

  # Usage:
  #
  # LtiLaunch.current(session[:session_id])
  def self.current(session_id)
    LtiLaunch.find_by!(state: session_id)
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
      :state => state,                       # State to identify browser session
      :nonce => nonce,                       # Prevent replay attacks 
      :login_hint =>  login_hint,            # Login hint to identify platform (aka Canvas) session
      :lti_message_hint => lti_message_hint  # Used by platform (aka Canvas) to store / identify context on their end. Opaque to us.
    }
  end
end

