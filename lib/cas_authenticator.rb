require 'bcrypt'
module BravenCAS
  class CustomAuthenticator < RubyCAS::Server::Core::Authenticator

    def validate(credentials)
      @user = User.find_by_email!(credentials[:username])
      # TODO: check whether they are confirmed as well and clean this up.
      #valid_password?(credentials[:password]) && active_for_authentication?
      valid_password?(credentials[:password])
    rescue ActiveRecord::RecordNotFound
      false
    end

    def valid_password?(password)
      return false if @user.encrypted_password.blank?
      BCrypt::Password.new(@user.encrypted_password) == password
    end

#  def active_for_authentication?
#    !@user.inactive && @user.confirmed?
#  end
#
#  def confirmed?
#    !!@user.confirmed_at
#  end

  end
end
