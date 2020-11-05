# frozen_string_literal: true

# Slack controller
class SlackController < ApplicationController
  layout 'admin'

  before_action :authorize_index

  def init_sync_to_slack
    @show_booster_slack_sync = booster_instance?
  end

  def sync_to_booster_slack
    redirect_to root_path, notice: 'Nothing happened! Run this on booster platform instead' and return unless booster_instance?

    email = params[:email]
    emails = params[:emails]

    SyncToBoosterSlackJob.perform_later(emails, email)

    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

  def sync_to_slack
    program_id = params[:program_id]
    email = params[:email]

    SyncToSlackJob.perform_later(program_id, email)

    redirect_to root_path, notice: 'The sync process was started. Watch out for an email'
  end

  private

  def booster_instance?
    ENV['BOOSTER_INSTANCE'].present?
  end

  def authorize_index
    authorize :application, :index?
  end
end
