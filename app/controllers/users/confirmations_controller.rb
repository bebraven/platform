# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
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
  # def show
  #   super
  # end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(_)
    new_user_confirmation_path 
  end

  # The path used after confirmation.
  def after_confirmation_path_for(_, _)
    # After confirming their account, have them login through CAS instead of being immediately signed in.
    # Note: if you wanted to sign them in, call this:
    # sign_in(resource)
    cas_login_url
  end


  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:create, keys: [:salesforce_id])
  end

  def cas_login_url
    ::Devise.cas_client.add_service_to_login_url(::Devise.cas_service_url(request.url, devise_mapping))
  end
  helper_method :cas_login_url
end
