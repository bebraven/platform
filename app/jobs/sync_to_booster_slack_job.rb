# frozen_string_literal: true

# Update booster slack job
class SyncToBoosterSlackJob < ApplicationJob
  queue_as :default

  def perform(emails, email)
    SyncBoosterSlackForEmails.new(emails: emails).run
    BackgroundSyncJobMailer.with(email: email).success_email.deliver_now

  rescue StandardError => _ 
    BackgroundSyncJobMailer.with(email: arguments.second).failure_email.deliver_now
    raise
  end
end
