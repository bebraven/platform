# frozen_string_literal: true

# Update booster slack job
class SyncToBoosterSlackJob < ApplicationJob
  queue_as :default

  def perform(emails, email)
    SyncBoosterSlackForEmails.new(emails: emails).run
    SyncSalesforceToLmsMailer.with(email: email).success_email.deliver_now
  end

  rescue_from(StandardError) do |exception|
    SyncSalesforceToLmsMailer.with(email: arguments.second).failure_email.deliver_now
    raise exception
  end
end
