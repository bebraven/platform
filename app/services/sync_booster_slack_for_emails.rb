# frozen_string_literal: true

require 'rowan_bot'

class SyncBoosterSlackForEmails
  def initialize(emails:)
    @emails = emails
  end

  def run
    tasks = RowanBot::Tasks.new
    salesforce_api = RowanBot::SalesforceAPI.new
    tasks.salesforce_api = salesforce_api
    tasks.slack_api = RowanBot::SlackAPI.new

    admin_emails = ENV.fetch('SLACK_ADMIN_EMAILS', '').split(',').map(&:strip)
    emails_a = emails.split(',').map(&:strip)
    salesforce_api.find_participants_by_emails(emails_a, 'Booster_Student')
    tasks.assign_to_booster_run_channels_in_slack(emails_a, admin_emails)
    tasks.assign_to_booster_peer_group_channel_in_slack(emails_a, admin_emails)
  end

  private

  attr_reader :emails
end
