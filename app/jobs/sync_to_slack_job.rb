# frozen_string_literal: true

# Update slack job
class SyncToSlackJob < ApplicationJob
  queue_as :default

  def perform(program_id, email)
    SyncSlackForProgram.new(salesforce_program_id: program_id).run
    sync_status = BackgroundSyncJobMailer.with(email: email)
    sync_status.success_email.deliver_now

  rescue StandardError => _ 
    BackgroundSyncJobMailer.with(email: arguments.second).failure_email.deliver_now
    raise
  end
end
