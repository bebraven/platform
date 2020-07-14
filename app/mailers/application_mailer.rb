# frozen_string_literal: true

# Base mailer class
class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@braven.org'
  layout 'mailer'
end
