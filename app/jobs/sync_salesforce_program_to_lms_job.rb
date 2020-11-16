# frozen_string_literal: true

# Salesforce program sync to lms job
class SyncSalesforceProgramToLmsJob < ApplicationJob
  queue_as :default

  def perform(program_id, email)
    SyncPortalEnrollmentsForProgram.new(salesforce_program_id: program_id).run
    BackgroundSyncJobMailer.with(email: email).success_email.deliver_now
  end

  rescue_from(StandardError) do |_exception|
    BackgroundSyncJobMailer.with(email: arguments.second).failure_email.deliver_now
  end
end
