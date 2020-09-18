# frozen_string_literal: true

class SyncJoinUsersForProgram
  def initialize(salesforce_program_id:)
    @sf_program_id = salesforce_program_id
    @sf_program = nil
  end

  def run
    entries = program_participants.map do |participant|
      portal_user = canvas_client.find_user_by(
        email: participant.email,
        salesforce_contact_id: participant.contact_id,
        student_id: participant.student_id
      )
      user = User.find_by(email: participant.email)
      if portal_user.nil? || user.nil?
        nil
      else
        { user: user, canvas_user_id: portal_user.id }
      end
    end.compact
    UpdateJoinUsers.new.run(entries)
  end

  attr_reader :sf_program_id

  def program_participants
    sf_client.find_participants_by(program_id: sf_program.id)
  end

  def sf_program
    @sf_program ||= sf_client.find_program(id: sf_program_id)
  end

  def sf_client
    SalesforceAPI.client
  end

  def canvas_client
    CanvasAPI.client
  end

end
