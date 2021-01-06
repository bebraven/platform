# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout 'accounts'

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #  super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  def after_resetting_password_path_for(resource)
    login_url = new_cas_login_url
    login_url += (URI.parse(login_url).query ? '&' : '?')
    login_url += "notice=Password reset successfully.".freeze
    login_url
  end

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(_)
    users_password_check_email_path
  end

  private

  def new_cas_login_url
    url_upto_question_mark = cas_login_url[0, cas_login_url.index('service')]
    service_param = URI.encode_www_form([ ['service', ENV['CANVAS_URL'] ]])
    url_upto_question_mark + service_param
  end
end
