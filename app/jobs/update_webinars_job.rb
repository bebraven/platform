# frozen_string_literal: true

# Update webinar job
class UpdateWebinarsJob < ApplicationJob
  queue_as :default

  def perform(program_id, email, force_update)
    UpdateWebinarLinksForProgram.new(salesforce_program_id: program_id, force_update: force_update).run
    SyncSalesforceToLmsMailer.with(email: email).success_email.deliver_now
  end

  rescue_from(StandardError) do |_exception|
    SyncSalesforceToLmsMailer.with(email: arguments.second).failure_email.deliver_now
  end
end
