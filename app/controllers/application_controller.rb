require 'rubycas-server-core/tickets'
require 'dry_crud'
require 'canvas_api'

class ApplicationController < ActionController::Base
  include RubyCAS::Server::Core::Tickets
  include DryCrud::Controllers
  include Pundit

  before_action :authenticate_user!
  after_action :remove_x_frame_options

  # This callback is a development helper that complains if an action has not explicitly
  # called `authorize`. It is *not* a fallback mechanism, and should not be relied upon
  # for added security. Its only purpose is to remind us to call `authorize` in each action.
  # The `unless` param excludes CasSessionsController from this check, since we have no
  # reason to call authorize in devise or CAS controller acitons.
  after_action :verify_authorized, unless: :devise_controller?

  private
  
  def authenticate_user!
    super unless authorized_by_token? || cas_ticket?
  end

  def authorized_by_token?
    return false unless request.format.symbol == :json

    key = params[:access_key] || request.headers['Access-Key']
    return false if key.nil?
    
    !!AccessToken.find_by(key: key)
  end

  def cas_ticket?
    ticket = params[:ticket]
    return false if ticket.nil?

    ServiceTicket.exists?(ticket: ticket)
  end

  # This is defined by :database_authenticable on the User model, but we're using :cas_authenticatable
  # However, we still want to support account creation, registration, and confirmation which is 
  # database_authenticable functionality so we need to define this for those built-in views to work.
  def new_session_path(_)
    new_user_session_path
  end
  helper_method :new_session_path

  def canvas_url
    CanvasAPI.client.canvas_url
  end
  helper_method :canvas_url

  # This is just the main login path that redirects to the proper place on success.
  # e.g. https://platform.bebraven.org/cas/login?service=https%3A%2F%2Fportal.bebraven.org%2Flogin%2Fcas
  def cas_login_url
    ::Devise.cas_client.add_service_to_login_url(::Devise.cas_service_url(request.url, devise_mapping))
  end
  helper_method :cas_login_url

  # Remove the default X-Frame-Options header Rails adds. We use CSP instead.
  # See config/initializers/content_security_policy.rb
  # Technically, CSP should take precedence anyway, but this is down to browser implementation, so
  # better to not take chances.
  def remove_x_frame_options
    response.headers.delete "X-Frame-Options"
  end

  # For LTI authentication (esp in a browser without access to cookies / session), the
  # state param is the de-facto "authenticated session" identifier. It is used to look up
  # the LtiLaunch for context on this "session"
  def current_state_param
    # TODO: the state param may be in one of three places, see: config/initializers/lti_authentication.rb 
    # Abstract that out into a common utility / way for any controller or lib or service to be able to 
    # access the state param of the current request. Perhaps using middleware? Like TracePropagation::Middleware does?
    # https://app.asana.com/0/1174274412967132/1191053265938819
    params[:state]
  end
  helper_method :current_state_param

end
