# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout 'accounts'
  before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource
  def show
    # Show the thank you for registering page.
    self.resource = User.find_by(salesforce_id: params[:u])
  end

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:salesforce_id])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up (assuming they don't need to be confirmed). For signup waiting on confirmation, use the method below.
  #def after_sign_up_path_for(resource)
  #   super(resource)
  #end

  # The path used after sign up for inactive accounts.
  # This shows a thank you page and let's them know to go confirm their account.
  def after_inactive_sign_up_path_for(resource)
    users_registration_path(:u => resource.salesforce_id)    
  end
end
