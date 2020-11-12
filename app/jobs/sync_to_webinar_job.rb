# frozen_string_literal: true

# Update webinar job
class SyncToWebinarJob < ApplicationJob
  queue_as :default

  def perform(program_id, email, force_update)
    SyncWebinarLinksForProgram.new(salesforce_program_id: program_id, force_update: force_update).run
    BackgroundSyncJobMailer.with(email: email).success_email.deliver_now
  end

  rescue_from(StandardError) do |exception|
    BackgroundSyncJobMailer.with(email: arguments.second).failure_email.deliver_now
    raise
  end
end
