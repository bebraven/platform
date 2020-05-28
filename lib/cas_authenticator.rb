require 'bcrypt'
module BravenCAS
  class CustomAuthenticator < RubyCAS::Server::Core::Authenticator

    def validate(credentials)
      @user = User.find_by_email!(credentials[:username])
      #valid_password?(credentials[:password]) && active_for_authentication?
      valid_password?(credentials[:password]) && @user.confirmed?
    rescue ActiveRecord::RecordNotFound
      false
    end

    def valid_password?(password)
      return false if @user.encrypted_password.blank?
      BCrypt::Password.new(@user.encrypted_password) == password
    end

  end
end
