# frozen_string_literal: true

# Webinar controller
class WebinarController < ApplicationController
  layout 'admin'

  def index
    authorize :application, :index?
  end

  def init_update_webinar
    authorize :application, :index?
  end

  def update_webinar
    authorize :application, :index?
    program_id = params[:program_id]
    email = params[:email]
    force_update = params[:force_update].eql?("1")
    UpdateWebinarsJob.perform_later(program_id, email, force_update)
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

end
