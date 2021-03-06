# frozen_string_literal: true

require 'rowan_bot'
require 'csv'

class GenerateWebinarForParticipants
  def initialize(meeting_id:, participants:)
    @meeting_id = meeting_id
    @participants = participants
  end

  def run
    tasks = RowanBot::Tasks.new(RowanBot::ZoomAPI.new)
    registrants = tasks.add_participants_to_meetings(@meeting_id, @participants)
    CSV.generate do |csv|
      csv << registrants.first.keys
      registrants.each { |registrant| csv << registrant.values }
    end
  end
end
