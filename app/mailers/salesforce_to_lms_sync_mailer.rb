# frozen_string_literal: true

# Salesforce sync response mailer
class SalesforceToLmsSyncMailer < ApplicationMailer
  def success_email
    mail(to: recipient, subject: 'Sync Successful')
  end

  def failure_email
    mail(to: recipient, subject: 'Sync Failed')
  end

  private

  def recipient
    params[:email]
  end
end
