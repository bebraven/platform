require 'braven_devise_mailer'

# Preview all emails at http://localhost/rails/mailers/braven_devise_mailer
class BravenDeviseMailerPreview < ActionMailer::Preview

  def confirmation_instructions
    BravenDeviseMailer.confirmation_instructions(User.first, "faketoken", {})
  end

  def reset_password_instructions
    BravenDeviseMailer.reset_password_instructions(User.first, "faketoken", {})
  end

end
