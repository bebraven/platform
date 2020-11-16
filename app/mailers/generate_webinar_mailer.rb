# frozen_string_literal: true

# Salesforce sync response mailer
class GenerateWebinarMailer < ApplicationMailer
  def success_email
    attachments['meeting_participants.csv'] = { mime_type: 'text/csv', content: attachment }
    mail(to: recipient, subject: 'Webinar Generation Successful')
  end

  def failure_email
    mail(to: recipient, subject: 'Webinar Generation Failed')
  end

  private

  def recipient
    params[:email]
  end

  def attachment
    params[:csv]
  end
end
