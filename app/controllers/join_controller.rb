# frozen_string_literal: true

# Join controller
class JoinController < ApplicationController
  layout 'admin'

  def init_sync_to_join
    authorize :application, :index?
  end

  def sync_to_join
    authorize :application, :update?

    program_id = params[:program_id]
    email = params[:email]
    SyncSalesforceProgramToJoinJob.perform_later(program_id, email)
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end
end
