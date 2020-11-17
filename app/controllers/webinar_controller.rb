# frozen_string_literal: true

require 'csv'

# Non-standard controller used to generate webinar links independently
# and generates webinar links from Salesforce
class WebinarController < ApplicationController
  layout 'admin'

  before_action :authorize_index

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() 
    false 
  end
  
  def generate_webinar
    participants = CSV.read(params[:participants].path, headers: true).map(&:to_h)
    GenerateWebinarJob.perform_later(params[:meeting_id], params[:email], participants)

    redirect_to root_path, notice: 'The generation process was started. Watch out for an email'
  end

  def sync_to_webinar
    SyncToWebinarJob.perform_later(params[:program_id], params[:email], params[:force_update].present?)
    
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

  private

  def authorize_index
    authorize :application, :index?
  end
end
