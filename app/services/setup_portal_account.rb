# frozen_string_literal: true

require 'join_api'

# Sets up portal account and join user
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
    user = User.find_by!(salesforce_id: sf_contact_id)
    join_user_id = find_or_create_join_user!(user, portal_user.id).id if should_create_join_user?
    sync_portal_enrollment!
    update_user_references!(user, salesforce_id: sf_contact_id,
                                  join_user_id: join_user_id)
    send_confirmation_notification(user)
  end

  private

  attr_reader :sf_contact_id, :portal_user

  def sync_portal_enrollment!
    SyncPortalEnrollmentForAccount
      .new(portal_user: portal_user,
           salesforce_participant: sf_participant,
           salesforce_program: sf_program)
      .run
  end

  def send_confirmation_notification(user)
    user.send_confirmation_instructions
  end

  def update_user_references!(user, salesforce_id:, join_user_id:)
    user.update!(canvas_user_id: portal_user.id, join_user_id: join_user_id)
    sf_client.update_contact(salesforce_id, canvas_user_id: portal_user.id)
    user
  end

  def find_or_create_join_user!(user, portal_user_id)
    UpdateJoinUsers.new.run([{ user: user, canvas_user_id: portal_user_id }]).first
  end

  def should_create_join_user?
    ENV['CREATE_JOIN_USER_ON_SIGN_UP'].present?
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
    @portal_user ||= canvas_client.find_user_by(
      email: sf_participant.email,
      salesforce_contact_id: sf_contact_id,
      student_id: sf_participant.student_id
    )
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

  def join_api_client
    JoinAPI.client
  end
end
