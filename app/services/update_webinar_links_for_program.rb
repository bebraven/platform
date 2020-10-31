# frozen_string_literal: true

require 'rowan_bot'

class UpdateWebinarLinksForProgram
  def initialize(salesforce_program_id:, force_update:)
    @sf_program_id = salesforce_program_id
    @force_update = force_update
  end

  def run
    tasks = RowanBot::Tasks.new
    tasks.salesforce_api = RowanBot::SalesforceAPI.new
    tasks.zoom_api = RowanBot::ZoomAPI.new

    tasks.assign_zoom_links_for_program(sf_program_id, force_update)
  end

  private

  attr_reader :sf_program_id, :force_update
end
