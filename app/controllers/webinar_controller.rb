# frozen_string_literal: true
#
require 'csv'

# Webinar controller
class WebinarController < ApplicationController
  layout 'admin'

  def init_sync_to_webinar
    authorize :application, :index?
  end

  def init_generate_webinar
    authorize :application, :index?
  end

  def generate_webinar
    authorize :application, :index?
    participants_file = params[:participants]
    participants = CSV.read(participants_file.path, headers: true).map(&:to_h)
    email = params[:email]
    meeting_id = params[:meeting_id]
    GenerateWebinarJob.perform_later(meeting_id, email, participants)
    redirect_to root_path, notice: 'The generation process was started. Watch out for an email'
  end

  def sync_to_webinar
    authorize :application, :index?
    program_id = params[:program_id]
    email = params[:email]
    force_update = params[:force_update].eql?("1")
    SyncToWebinarJob.perform_later(program_id, email, force_update)
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

end
