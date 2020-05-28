require 'rubycas-server-core/util'
require 'rubycas-server-core/tickets'
require 'rubycas-server-core/tickets/validations'
require 'rubycas-server-core/tickets/generations'

class CasController < ApplicationController
  layout 'accounts'
  skip_before_action :authenticate_user!
  skip_before_action :ensure_admin!
  
  before_action :set_settings
  before_action :set_request_client
  before_action :set_params

  # Note that the following helper classes in this controller come from this module
  # TGT = Ticket Granting Ticket
  # ST = Service Ticket
  # LT = Login Ticket
  # PGT = Proxy Granting Ticket
  # PT = Proxy Ticket
  include RubyCAS::Server::Core::Tickets

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?
    false
  end

  def login
    # make sure there's no caching
    request.headers['Pragma'] = 'no-cache'
    request.headers['Cache-Control'] = 'no-store'
    request.headers['Expires'] = (Time.now - 1.year).rfc2822

    # optional params
    @gateway = params['gateway'] == 'true' || params['gateway'] == '1'
    @message = { :type => 'notice', :message => params[:notice] } if params[:notice]
 

    if tgc = request.cookies['tgt']
      tgt, tgt_error = TGT.validate(tgc)
    end

    if tgt && !tgt_error
      @message = {
        :type => 'notice',
        :message => "You are currently logged in as '#{tgt.username}'. If this is not you, please log in below."
      }
    elsif tgt_error
      logger.debug("Ticket granting cookie could not be validated: #{tgt_error}")
    elsif !tgt
      logger.debug("No ticket granting ticket detected.")
    end

    if params['redirection_loop_intercepted']
      @message = {
        :type => 'mistake',
        :message => "The client and server are unable to negotiate authentication. Please try logging in again later."
      }
    end

    begin
      if @service
        if @renew
          logger.info("Authentication renew explicitly requested. Proceeding with CAS login for service #{@service.inspect}.")
        elsif tgt && !tgt_error
          logger.debug("Valid ticket granting ticket detected.")
          st = ST.create! @service, tgt.username, tgt, @request_client
          logger.info("User '#{tgt.username}' authenticated based on ticket granting cookie. Redirecting to service '#{@service}'.")
          redirect_to Utils.build_ticketed_url(@service, st) and return
        elsif @gateway
          logger.info("Redirecting unauthenticated gateway request to service '#{@service}'.")
          return redirect_to @service, status: 303
        else
          logger.info("Proceeding with CAS login for service #{@service.inspect}.")
        end
      elsif @gateway
          logger.error("This is a gateway request but no service parameter was given!")
          @message = {
            :type => 'mistake',
            :message => "The server cannot fulfill this gateway request because no service parameter was given."
          }
      else
        logger.info("Proceeding with CAS login without a target service.")
      end
    rescue URI::InvalidURIError
      logger.error("The service '#{@service}' is not a valid URI!")
      @message = {:type => 'mistake',
        :message => "The target service your browser supplied appears to be invalid. Please contact your system administrator for help."
      }
    end

    lt = LT.create! @request_client

    logger.debug("Rendering login form with lt: #{lt}, service: #{@service}, renew: #{@renew}, gateway: #{@gateway}")

    @lt = lt.ticket

    # If the 'onlyLoginForm' parameter is specified, we will only return the
    # login form part of the page. This is useful for when you want to
    # embed the login form in some external page (as an IFRAME, or otherwise).
    # The optional 'submitToURI' parameter can be given to explicitly set the
    # action for the form, otherwise the server will try to guess this for you.
    if params.has_key? 'onlyLoginForm'
      if request.env['HTTP_HOST']
        @protocol = request.env['HTTPS'] == 'on' ? 'https' : 'http'
        guessed_login_uri = "#{@protocol}://#{request.env['REQUEST_URI']}/cas/login"
      else
        guessed_login_uri = nil
      end

      @form_action = params['submitToURI'] || guessed_login_uri

      if @form_action
        return render :_login_form
      else
        return render :json => {:response => "Could not guess the CAS login URI. Please supply a submitToURI parameter with your request."}, status: :internal_server_error
      end
    else
      render :login
    end
  end

  def loginpost
    @username = params['username'].downcase.strip
    @password = params['password']
    @lt = params['lt']

    if !result = LT.validate(@lt)
      @message = {:type => 'mistake', :message => error}
      # generate another login ticket to allow for re-submitting the form
      @lt = LT.create!(@request_client).ticket
      return render :login, status: :unauthorized
    end

    # generate another login ticket to allow for re-submitting the form after a post
    @lt = LT.create!(@request_client).ticket

    logger.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{@settings.inspect}")

    credentials_are_valid = false
    extra_attributes = {}
    successful_authenticator = nil
    begin
      @settings[:auth].each do |auth_class, auth_index|
        auth = auth_class.new

        auth_config = @settings[:authenticator]
        # pass the authenticator index to the configuration hash in case the authenticator needs to know
        # it splace in the authenticator queue
        auth.configure(auth_config.merge('auth_index' => auth_index))

        credentials_are_valid = auth.validate(
          :username => @username,
          :password => @password,
          :service => @service,
          :request => request.env
        )
        if credentials_are_valid
          extra_attributes.merge!(auth.extra_attributes) unless auth.extra_attributes.blank?
          successful_authenticator = auth
          break
        end
      end

      if credentials_are_valid
        logger.info("Credentials for username '#{@username}' successfully validated using #{successful_authenticator.class.name}.")
        logger.debug("Authenticator provided additional user attributes: #{extra_attributes.inspect}") unless extra_attributes.blank?

        tgt = TGT.create! @username, @request_client, false, extra_attributes
        response.set_cookie('tgt', tgt.to_s)

        logger.debug("Ticket granting cookie '#{tgt.inspect}' granted to #{@username.inspect}")

        if @service.blank?
          logger.info("Successfully authenticated user '#{@username}' at '#{tgt.client_hostname}'. No service param was given, so we will not redirect.")
          @message = {:type => 'confirmation', :message => "You have successfully logged in."}
        else
          @st = ST.create! @service, @username, tgt, @request_client

          begin
            logger.info("Redirecting authenticated user '#{@username}' at '#{@st.client_hostname}' to service '#{@service}'")
            redirect_to Utils.build_ticketed_url(@service, @st) and return
          rescue URI::InvalidURIError
            logger.error("The service '#{@service}' is not a valid URI!")
            @message = {
              :type => 'mistake',
              :message => "The target service your browser supplied appears to be invalid. Please contact your system administrator for help."
            }
          end
        end
      else
        user = User.find_by_email(@username)
        unconfirmed_user = user && user.confirmed? == false
        if unconfirmed_user
          logger.warn("Unconfirmed user tried to login: '#{@username}'")
          @message = { :type => 'mistake', :message => "Please confirm your account by clicking on the link in the email you received first." }
        else
          logger.warn("Invalid credentials given for user '#{@username}'")
          @message = { :type => 'mistake', :message => "Incorrect username or password." }
        end
        return render :login, status: :unauthorized
      end
    rescue RubyCAS::Server::Core::AuthenticatorError => e
      logger.error(e)
      # generate another login ticket to allow for re-submitting the form
      @lt = LT.create!(@request_client).ticket
      @message = {:type => 'mistake', :message => e.to_s}
      return render :login , status: :unauthorized
    end

    render :login
  end

  def logout
    # The behaviour here is somewhat non-standard. Rather than showing just a blank
    # "logout" page, we take the user back to the login page with a "you have been logged out"
    # message, allowing for an opportunity to immediately log back in. This makes it
    # easier for the user to log out and log in as someone else.

    # BZ modification: always use default service so logout/login goes back to our main
    # site (which can redirect) regardless of where they came from
    @service = @service || Utils.clean_service_url(@settings[:default_service])
    @continue_url = params['url']

    @gateway = params['gateway'] == 'true' || params['gateway'] == '1'

    tgt = TicketGrantingTicket.find_by({ticket: request.cookies['tgt'],})
    response.delete_cookie 'tgt'

    if tgt
      TicketGrantingTicket.transaction do
        logger.debug("Deleting Service/Proxy Tickets for '#{tgt}' for user '#{tgt.username}'")
        tgt.service_tickets.each do |st|
          ST.send_logout_notification_for_service_ticket(st) if @settings[:enable_single_sign_out]
          logger.debug "Deleting #{st.class.name.demodulize} #{st.ticket.inspect} for service #{st.service}."
          st.destroy
        end

        # TODO: Figure out how to grab all the tickets with rubycas activerecord
        # pgts = ProxyGrantingTicket.find(:all,
        #   :conditions => [ServiceTicket.quoted_table_name+".username = ?", tgt.username],
        #   :include => :service_ticket
        # )
        # pgts.each do |pgt|
        #   logger.debug("Deleting Proxy-Granting Ticket '#{pgt}' for user '#{pgt.service_ticket.username}'")
        #   pgt.destroy
        # end

        logger.debug("Deleting #{tgt.class.name.demodulize} '#{tgt}' for user '#{tgt.username}'")
        tgt.destroy
      end

      logger.info("User '#{tgt.username}' logged out.")
    else
      logger.warn("User tried to log out without a valid ticket-granting ticket.")
    end

    @message = {:type => 'confirmation', :message => "You have successfully logged out."}

    @message[:message] +=  "Please click on the following link to continue:" if @continue_url

    @log_out_of_services = true

    @lt = LT.create! @request_client

    if current_user
      sign_out_and_redirect(current_user) and return
    elsif @gateway && @service
      return render :login
    elsif @continue_url
      return render :logout
    end
    render :login
  end

  def loginTicket
    logger.error("Tried to use login ticket dispenser with get method!")
    render :json => {:response => "To generate a login ticket, you must make a POST request."}, status: :unprocessable_entity
  end
  
  # Renders a page with a login ticket (and only the login ticket)
  # in the response body.
  def loginTicketPost
    lt = LT.create! @request_client

    logger.debug("Dispensing login ticket #{lt} to host #{@request_client.inspect}")

    render :json => {:ticket => lt.ticket}
  end

  def validate
    st, @error = ST.validate(@service, @ticket)

    return render json: {error: @error}, status: :unprocessable_entity if @error

    @success = !st.nil? && !@error
    @username = st.username if @success

    render(json: {success: @success, user: @username})
  end
  
  def serviceValidate
    @pgt_url = params['pgtUrl']

    st, @error = ST.validate(@service, @ticket)
    @success = !st.nil? && !@error

    if @success
      @username = st.username
      if @pgt_url
        pgt = PGT.create @pgt_url, st, @request_client
        @pgtiou = pgt.iou if pgt
      end
      tgt = TGT.find_by(id: st.ticket_granting_ticket_id)
      @extra_attributes = JSON.parse(tgt.extra_attributes) if tgt
    end

    render :service_validate, formats: [:xml]
  end
  
  def proxyValidate
    @pgt_url = params['pgtUrl']

    pt, @error = PT.validate(@service, @ticket)

    @success = !pt.nil? && !@error
    @proxies = []
    if @success
      @username = pt.username

      if pt.kind_of? ProxyTicket
        st = ST.find_by(id: pt.service_ticket_id)
        tgt = TGT.find_by(id: st.ticket_granting_ticket_id)
        @proxies << st.service if st
        @extra_attributes = JSON.parse(tgt.extra_attributes) if tgt
      end

      if @pgt_url
        pgt = PGT.create @pgt_url, pt, @request_client
        @pgtiou = pgt.iou if pgt
      end
    end

    render :proxy_validate, formats: [:xml]
  end

  def proxy
    @ticket = params['pgt']
    @target_service = params['targetService']

    pgt, @error = PGT.validate(@ticket)

    @success = !pgt.nil? && !@error
    @pt = PT.create! @target_service, pgt, @request_client if @success

    render :proxy, formats: [:xml]
  end

  class PGT
    include RubyCAS::Server::Core::Tickets::Validations
  end

  private

  def set_request_client
    @request_client = request.env['HTTP_X_FORWARDED_FOR'] || request.env['REMOTE_HOST'] || request.env['REMOTE_ADDR']
  end

  def set_settings
    @settings = RubyCAS::Server::Core::Settings._settings
  end

  def set_params
    @service = Utils.clean_service_url(params['service']) if params['service']
    @ticket = params['ticket'] || nil
    @renew = params['renew'] || nil
    @extra_attributes = {}
  end 
end

# TODO: move this to the rubycas-server-core gem here:
# lib/rubycas-server-core/tickets.rb
module RubyCAS
  module Server
    module Core
      module Tickets
        class PGT
          extend ::RubyCAS::Server::Core::Tickets::Generations
          extend ::RubyCAS::Server::Core::Tickets::Validations
          def self.validate(pgt)
            validate_proxy_granting_ticket(pgt)
          end

          def self.create(pgt_url, pt, client = "localhost")
            generate_proxy_granting_ticket(pgt_url, pt, client)
          end
        end

        class PT
          extend ::RubyCAS::Server::Core::Tickets::Generations
          extend ::RubyCAS::Server::Core::Tickets::Validations
          def self.validate(service, ticket)
            validate_proxy_ticket(service, ticket)
          end

          def self.create(target_service, pgt, client = "localhost")
            generate_proxy_ticket(target_service, pgt, client)
          end
        end

        class ST
          extend ::RubyCAS::Server::Core::Tickets::Generations
          extend ::RubyCAS::Server::Core::Tickets::Validations
          def self.send_logout_notifications(st)
            send_logout_notification_for_service_ticket(st)
          end
        end
      end
    end
  end
end
