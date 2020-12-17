# frozen_string_literal: true

# A helper service to perform the logic that takes folks who are confirmed as participants in the
# program in Salesforce and creates their Canvas accounts. Also, moves/drops/completes their
# enrollment when things change.
class SyncPortalEnrollmentForAccount
  DEFAULT_SECTION = 'Default Section'

  def initialize(portal_user:, salesforce_participant:, salesforce_program:)
    @portal_user = portal_user
    @sf_participant = salesforce_participant
    @sf_program = salesforce_program
    @user = User.find_by!(email: sf_participant.email)
  end

  # Syncs the Canvas enrollments for the given user in the given course, by unenrolling
  # from existing courses, if necessary, and enrolling them in the new course+section.
  #
  # Note: canvas_role = [:StudentEnrollment, :TaEnrollment, :DesignerEnrollment, :TeacherEnrollment]
  def run
    logger.info("Started sync enrollment for #{sf_participant.email}")
    case sf_participant.status
    when SalesforceAPI::ENROLLED
      add_enrollment!
    when SalesforceAPI::DROPPED
      drop_enrollment!
    when SalesforceAPI::COMPLETED
      complete_enrollment!
    else
      logger.warn("Doing nothing! Got #{sf.participant.status} from SF")
    end
  end

  private

  attr_reader :portal_user, :sf_participant, :sf_program, :user

  # The logic for who get's sync'd is anyone with a ParticipantStatus == 'Enrolled'. If they have a CohortName
  # set, they are put in a Canvas Section with that name. If it's not set, they are put in a placeholder cohort
  # that corresponds to the day and time that their Learning Lab meets.
  #
  # Assumptions: there are no duplicate Participant objects and if they opt out or drop as a Candidate, the ParticipantStatus is
  # updated accordingly.
  def add_enrollment!
    case sf_participant.role
    when SalesforceAPI::LEADERSHIP_COACH
      sync_enrollment(sf_program.fellow_course_id, RoleConstants::TA_ENROLLMENT,
                      course_section_name)
      sync_enrollment(sf_program.leadership_coach_course_id,
                      RoleConstants::STUDENT_ENROLLMENT,
                      sf_program.leadership_coach_course_section_name)
    when SalesforceAPI::FELLOW
      sync_enrollment(sf_program.fellow_course_id, RoleConstants::STUDENT_ENROLLMENT,
                      course_cohort_name, Section::COHORT)
      sync_enrollment(sf_program.fellow_course_id, RoleConstants::STUDENT_ENROLLMENT,
                      course_cohort_schedule_name, Section::COHORT_SCHEDULE)
    else
      logger.warn("Got unknown role #{sf_participant.role} from SF")
    end
  end

  def course_cohort_name
    sf_participant.cohort  # E.g. SJSU Brian (Tues)
  end

  def course_cohort_schedule_name
    sf_participant.cohort_schedule  # E.g. 'Monday, 7:00'
  end

  def drop_enrollment!
    case sf_participant.role
    when SalesforceAPI::LEADERSHIP_COACH
      drop_course_enrollment(sf_program.leadership_coach_course_id)
      drop_course_enrollment(sf_program.fellow_course_id)
    when SalesforceAPI::FELLOW
      drop_course_enrollment(sf_program.fellow_course_id)
    else
      logger.warn("Got unknown role #{sf_participant.role} from SF")
    end
  end

  def complete_enrollment!
    # NOOP
    # We haven't figured out this yet
  end

  def drop_course_enrollment(canvas_course_id)
    enrollment = find_user_enrollment(canvas_course_id)
    return if enrollment.nil?

    logger.info('Removing user enrollment from canvas')
    canvas_client.delete_enrollment(enrollment: enrollment)
    section = Section.find_by!(canvas_section_id: enrollment.section_id)
    # remove_role passes if the role doesn't exist.
    user.remove_role enrollment.type, section
  end

  # Enroll or update their enrollment in the proper course and section
  def sync_enrollment(canvas_course_id, role, section_name, section_type='')
    section_name = section_name.blank? ? DEFAULT_SECTION : section_name
    section = find_or_create_section(canvas_course_id, section_name, section_type)
    enrollment = find_user_enrollment(canvas_course_id)
    if enrollment.nil?
      enroll_user(canvas_course_id, role, section)
    elsif !enrollment.section_id.eql?(section.id) || !enrollment.type.eql?(role)
      drop_course_enrollment(canvas_course_id)
      enroll_user(canvas_course_id, role, section)
    else
      logger.warn('Skipping as user enrollment looks fine')
    end
  end

  # Pass in a local db section.
  def enroll_user(canvas_course_id, role, section)
    user.add_role role, section
    canvas_client.enroll_user_in_course(
      portal_user.id, canvas_course_id, role, section.canvas_section_id
    )
  end

  # Creates a local DB Section and a Canvas section, but only returns the local one.
  def find_or_create_section(canvas_course_id, section_name, section_type)
    canvas_section = find_canvas_course_section(canvas_course_id, section_name)
    if canvas_section.nil?
      canvas_section = canvas_client.create_lms_section(course_id: canvas_course_id, name: section_name)
    end

    course = Course.find_by!(canvas_course_id: canvas_course_id)
    section = Section.find_or_create_by!(
      course_id: course.id,
      name: section_name,
      canvas_section_id: canvas_section.id,
    )
    section.update!(salesforce_type: section_type)
    section
  end

  # Returns Canvas section.
  def find_canvas_course_section(canvas_course_id, section_name)
    canvas_client.find_section_by(course_id: canvas_course_id, name: section_name)
  end

  def find_user_enrollment(canvas_course_id)
    canvas_client.find_enrollment(user_id: portal_user.id, course_id: canvas_course_id)
  end

  def canvas_client
    CanvasAPI.client
  end

  def logger
    Rails.logger
  end
end
