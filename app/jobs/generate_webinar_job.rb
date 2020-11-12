# frozen_string_literal: true

# Generate webinar job
class GenerateWebinarJob < ApplicationJob
  queue_as :default

  def perform(meeting_id, email, participants)
    csv = GenerateWebinarForParticipants.new(meeting_id: meeting_id, participants: participants).run
    GenerateWebinarMailer.with(email: email, csv: csv).success_email.deliver_now
  end

  rescue_from(StandardError) do |exception|
    GenerateWebinarMailer.with(email: arguments.second).failure_email.deliver_now
    raise
  end
end
