# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  include RubyCAS::Server::Core::Tickets

  layout 'accounts'
  before_action :configure_permitted_parameters

  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  def create
    super do
      self.resource = User.find_by(salesforce_id: params[:user][:salesforce_id])
      resource.send_confirmation_instructions
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    super do
      Rails.logger.debug("Account creation confirmed for #{resource}. Signing them in using CAS SSO.")
      redirect_path_for_user = sign_in_and_get_redirect_path
      set_flash_message!(:notice, :confirmed)
      redirect_to redirect_path_for_user and return
    end
  end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(_)
    new_user_confirmation_path 
  end

#  # The path used after confirmation.
#  def after_confirmation_path_for(resource_name, resource)
#    cas_login_url
#  end

  # Does a CAS SSO login for the app they are redirected to on login. E.g. if they have Canvas access,
  # auto-log them in there, otherwise do it here in the platform.
  def sign_in_and_get_redirect_path
     username = resource.email
     if resource.canvas_id
       login_service_url = URI.join(CanvasAPI.client.canvas_url, "/login/cas").to_s
     else
       login_service_url = ::Devise.cas_service_url(request.url, devise_mapping) 
     end

     # TGT = Ticket Granting Ticket helper, ST = Service Ticket helper. See: lib/rubycas-server-core/tickets.rb 
     tgt = TGT.create! username, ::Devise.cas_client
     response.set_cookie('tgt', tgt.to_s) # When the app calls back to validate the ticket, this is what makes that work.
     st = ST.create! login_service_url, username, tgt, ::Devise.cas_client

     Rails.logger.debug("Done signing in confirmed user #{username} with CAS Ticket granting cookie '#{tgt.inspect}' and Service Ticket #{st.inspect}")

     Utils.build_ticketed_url(login_service_url, st)
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:create, keys: [:salesforce_id])
  end

end
