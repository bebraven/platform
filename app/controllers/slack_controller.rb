# frozen_string_literal: true

# A non standard controller used to initiate syncs from Salesforce into Slack cohorts
class SlackController < ApplicationController
  layout 'admin'

  before_action :authorize_index
  
  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() 
    false 
  end

  def init_sync_to_slack
    @show_booster_slack_sync = booster_instance?
  end

  def sync_to_booster_slack

    the_notice = nil
    if booster_instance?
      SyncToBoosterSlackJob.perform_later(email_to_notify, emails_to_sync)
      'The sync process was started. Watch out for an email'
    else
      'Nothing happened! Run this on booster platform instead'
    end

    redirect_to_root_path(notice: the_notice)
  end

  def sync_to_slack
    SyncToSlackJob.perform_later(params[:program_id], email_to_notify)

    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

  private

  def email_to_notify
    params[:email]
  end

  def emails_to_sync
    params[:emails]
  end

  def booster_instance?
    ENV['BOOSTER_INSTANCE'].present?
  end

  def authorize_index
    authorize :application, :index?
  end
end
