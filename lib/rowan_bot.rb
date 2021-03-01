# this is the worst. I'm going to remove this cruft. -- hcli

require 'rowan_bot/docusign_api'
require 'rowan_bot/salesforce_api'
require 'rowan_bot/slack_api'
require 'rowan_bot/tasks'
require 'rowan_bot/zoom_api'

# RowanBot module
module RowanBot
  class Error < StandardError; end

  # We'll log to STDOUT for now since we're only using it in the terminal for
  # now
  @logger = Logger.new(STDOUT)

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
