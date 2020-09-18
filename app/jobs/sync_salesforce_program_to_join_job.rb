# frozen_string_literal: true

class SyncSalesforceProgramToJoinJob < ApplicationJob
  queue_as :default

  def perform(program_id, email)
    SyncJoinUsersForProgram.new(salesforce_program_id: program_id).run
    SyncSalesforceToJoinMailer.with(email: email).success_email.deliver_now
  end

  rescue_from(StandardError) do |_exception|
    SyncSalesforceToJoinMailer.with(email: arguments.second).failure_email.deliver_now
  end

end
