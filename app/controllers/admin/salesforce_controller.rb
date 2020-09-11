# frozen_string_literal: true

# Salesforce controller
class Admin::SalesforceController < ApplicationController
  layout 'admin'

  def init_sync_to_lms; end

  def sync_to_lms
    program_id = params[:program_id]
    email = params[:email]
    SyncSalesforceProgramToLmsJob.perform_later(program_id, email)
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end
end
