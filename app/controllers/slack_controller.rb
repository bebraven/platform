# frozen_string_literal: true

# Slack controller
class SlackController < ApplicationController
  layout 'admin'

  def init_sync_to_slack
    authorize :application, :index?
    @show_booster_slack_sync = booster_instance?
  end

  def init_sync_to_booster_slack
    authorize :application, :index?
  end

  def sync_to_booster_slack
    authorize :application, :index?
    redirect_to root_path, notice: 'Nothing happened! Run this on booster platform instead' and return unless booster_instance?

    email = params[:email]
    emails = params[:emails]
    SyncToBoosterSlackJob.perform_later(emails, email)
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

  def sync_to_slack
    authorize :application, :index?
    program_id = params[:program_id]
    email = params[:email]
    SyncToSlackJob.perform_later(program_id, email)
    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

  private

  def booster_instance?
    ENV['BOOSTER_INSTANCE'].present?
  end
end
