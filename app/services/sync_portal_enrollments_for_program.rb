# frozen_string_literal: true

class SyncPortalEnrollmentsForProgram
  def initialize(salesforce_program_id:)
    @sf_program_id = salesforce_program_id
    @sf_program = nil
  end

  def run
    program_participants.each do |participant|
      portal_user = canvas_client.find_user_by(
        email: participant.email,
        salesforce_contact_id: participant.contact_id,
        student_id: participant.student_id
      )
      if portal_user.present?
        reconcile_email!(portal_user, participant) if email_inconsistent?(portal_user, participant)
        sync_portal_enrollment!(portal_user, participant)
      elsif sf_program.nlu? && participant.student_id.nil?
        run_account_creation_for_nlu!(participant.contact_id)
      else
        Rails.logger.debug("no portal account yet for '#{participant.email}'; skipping")
        next
      end
    end
  end

  private

  attr_reader :sf_program_id

  def email_inconsistent?(portal_user, participant)
    !participant.email.casecmp(portal_user.email).zero?
  end

  def run_account_creation_for_nlu!(contact_id)
    AccountCreator.new(
      sign_up_params: { 'salesforce_id' => contact_id },
      for_nlu: true
    ).run
  end

  def reconcile_email!(portal_user, participant)
    ReconcileUserEmail.new(salesforce_participant: participant,
                           portal_user: portal_user)
                      .run
  end

  def sync_portal_enrollment!(portal_user, participant)
    SyncPortalEnrollmentForAccount
      .new(portal_user: portal_user,
           salesforce_participant: participant,
           salesforce_program: sf_program)
      .run
  end

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
