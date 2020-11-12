# frozen_string_literal: true

require 'rowan_bot'

class SyncSlackForProgram
  def initialize(salesforce_program_id:)
    @sf_program_id = salesforce_program_id
  end

  def run
    tasks = RowanBot::Tasks.new
    salesforce_api = RowanBot::SalesforceAPI.new
    tasks.salesforce_api = salesforce_api
    program = salesforce_api.find_program_by_id(@sf_program_id)
    tasks.slack_api = RowanBot::SlackAPI.new({ slack_url: program.slack_url,
                                               slack_token: program.slack_token,
                                               slack_user: program.slack_user,
                                               slack_password: program.slack_password,
                                               slack_admin_emails: program.slack_admin_emails })
    slack_admins = program.slack_admin_emails.split(',').map { |email| { email: email.strip } }
    tasks.sync_program_to_slack(program.id, slack_admins)
  end
end
