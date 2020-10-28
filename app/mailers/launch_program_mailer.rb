# frozen_string_literal: true

class LaunchProgramMailer < ApplicationMailer
  def success_email
    mail(to: recipient, subject: 'New Program Launch Successful')
  end

  def failure_email
    @exception = params[:exception]
    mail(to: recipient, subject: 'New Program Launch Failed - Uh Oh')
  end

  private

  def recipient
    params[:email]
  end
end
