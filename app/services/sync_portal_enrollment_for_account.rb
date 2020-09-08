# frozen_string_literal: true

class SyncPortalEnrollmentForAccount
  DEFAULT_SECTION = 'Default Section'

  def initialize(portal_user:, salesforce_participant:, salesforce_program:)
    @portal_user = portal_user
    @sf_participant = salesforce_participant
    @sf_program = salesforce_program
  end

  def run
    case sf_participant.status
    when SalesforceAPI::ENROLLED
      add_enrollment!
    when SalesforceAPI::DROPPED
      drop_enrollment!
    when SalesforceAPI::COMPLETED
      complete_enrollment!
    end
    # Log warning for else case
  end

  private

  attr_reader :portal_user, :sf_participant, :sf_program

  def add_enrollment!
    case sf_participant.role
    when SalesforceAPI::LEADERSHIP_COACH
      sync_enrollment(sf_program.fellow_course_id, CanvasAPI::TA_ENROLLMENT, 
                      course_section_name)
      sync_enrollment(sf_program.leadership_coach_course_id,
                      CanvasAPI::STUDENT_ENROLLMENT,
                      sf_program.leadership_coach_course_section_name)
    when SalesforceAPI::FELLOW
      sync_enrollment(sf_program.fellow_course_id, CanvasAPI::STUDENT_ENROLLMENT, 
                      course_section_name)
    end
    # Log warning for else case
  end

  def course_section_name
    sf_participant.cohort || sf_participant.cohort_schedule
  end

  def drop_enrollment!
    case sf_participant.role
    when SalesforceAPI::LEADERSHIP_COACH
      drop_course_enrollment(sf_program.leadership_coach_course_id)
      drop_course_enrollment(sf_program.fellow_course_id)
    when SalesforceAPI::FELLOW
      drop_course_enrollment(sf_program.fellow_course_id)
    end
    # Log warning for else case
  end

  def complete_enrollment!
    # NOOP Maybe log info
  end

  def drop_course_enrollment(course_id)
    enrollment = find_user_enrollment(course_id)
    return if enrollment.nil?

    canvas_client.delete_enrollment(enrollment: enrollment)
  end

  def sync_enrollment(course_id, role, section_name)
    section_name = section_name.blank? ? DEFAULT_SECTION : section_name
    section = find_or_create_section(course_id, section_name)
    enrollment = find_user_enrollment(course_id)
    if enrollment.nil?
      enroll_user(course_id, role, section)
    elsif !enrollment.section_id.eql?(section.id) || !enrollment.type.eql?(role)
      canvas_client.delete_enrollment(enrollment: enrollment)
      enroll_user(course_id, role, section)
    end
  end

  def enroll_user(course_id, role, section)
    canvas_client.enroll_user_in_course(
      portal_user.id, course_id, role, section.id
    )
  end

  def find_or_create_section(course_id, section_name)
    section = find_course_section(course_id, section_name)
    if section.nil?
      canvas_client.create_lms_section(course_id: course_id, name: section_name)
    else
      section
    end
  end

  def find_course_section(course_id, section_name)
    canvas_client.find_section_by(course_id: course_id, name: section_name)
  end

  def find_user_enrollment(course_id)
    canvas_client.find_enrollment(user_id: portal_user.id, course_id: course_id)
  end

  def canvas_client
    CanvasAPI.client
  end
end
