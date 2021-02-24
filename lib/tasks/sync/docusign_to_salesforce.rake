require 'rowan_bot'
# frozen_string_literal: true

namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce, [:days] do |_, args|
    days = args[:days] ? args[:days].to_i : 1

    tasks = RowanBot::Tasks.new
    tasks.docusign_api = RowanBot::DocuSignAPI.new
    tasks.salesforce_api = RowanBot::SalesforceAPI.new
    tasks.slack_api = RowanBot::SlackAPI.new
    tasks.zoom_api = RowanBot::ZoomAPI.new
    emails = tasks.sync_booster_signed_waivers_to_salesforce(days)

    unless emails.empty?
      tasks.assign_peer_groups_to_booster_users(emails)
      tasks.assign_zoom_links_to_booster_participants(emails)
    end
    tasks.send_onboarding_notification(emails)
  end
end
