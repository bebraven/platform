# frozen_string_literal: true

# Update slack job
class SyncToSlackJob < ApplicationJob
  queue_as :default

  def perform(program_id, email)
    SyncSlackForProgram.new(salesforce_program_id: program_id).run
    SyncSalesforceToLmsMailer.with(email: email).success_email.deliver_now
  end

  rescue_from(StandardError) do |exception|
    SyncSalesforceToLmsMailer.with(email: arguments.second).failure_email.deliver_now
    raise exception
  end
end
