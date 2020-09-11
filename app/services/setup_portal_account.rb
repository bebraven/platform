# frozen_string_literal: true

class SetupPortalAccount
  UserNotEnrolledOnSFError = Class.new(StandardError)

  def initialize(salesforce_contact_id:)
    @sf_contact_id = salesforce_contact_id
    @sf_participant = nil
    @sf_program = nil
    @portal_user = nil
  end

  def run
    find_or_create_portal_user!
    SyncPortalEnrollmentForAccount
      .new(portal_user: portal_user,
           salesforce_participant: sf_participant,
           salesforce_program: sf_program)
      .run
    user = update_portal_references!
    send_confirmation_notification(user)
  end

  private

  attr_reader :sf_contact_id

  def send_confirmation_notification(user)
    user.send_confirmation_instructions
  end

  def update_portal_references!
    user = User.find_by!(salesforce_id: sf_contact_id)
    user.update!(canvas_id: portal_user.id)
    sf_client.update_contact(sf_contact_id, canvas_id: portal_user.id)
    user
  end

  def find_or_create_portal_user!
    if portal_user.nil?
      raise UserNotEnrolledOnSFError, "Contact ID #{sf_contact_id}" unless sf_participant_enrolled?

      # TODO: Revert to create_user when fully deptrecated
      @portal_user = canvas_client.create_account(
        first_name: sf_participant.first_name,
        last_name: sf_participant.last_name,
        user_name: portal_username,
        email: sf_participant.email,
        contact_id: sf_contact_id,
        student_id: sf_participant.student_id,
        timezone: sf_program.timezone,
        docusign_template_id: docusign_template_id
      )
    else
      portal_user
    end
  end

  def sf_participant_enrolled?
    sf_participant.status.eql?(SalesforceAPI::ENROLLED)
  end

  def docusign_template_id
    if sf_participant.role.eql?(SalesforceAPI::LEADERSHIP_COACH)
      sf_program.lc_docusign_template_id
    else
      sf_program.docusign_template_id
    end
  end

  def portal_username
    # TODO: For now it's email but there are cases like NLU where is
    # #{user_student_id}@nlu.edu
    sf_participant.email
  end

  def portal_user
    @portal_user ||= canvas_client.find_user_by(email: sf_participant.email)
  end

  def sf_participant
    @sf_participant ||= sf_client.find_participant(contact_id: sf_contact_id)
  end

  def sf_program
    @sf_program ||= sf_client.find_program(id: sf_participant.program_id)
  end

  def sf_client
    SalesforceAPI.client
  end

  def canvas_client
    CanvasAPI.client
  end
end
