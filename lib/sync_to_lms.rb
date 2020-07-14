require 'salesforce_api'
require 'canvas_api'

# A helper library to perform the logic that takes folks who are confirmed as participants in the
# program in Salesforce and creates their Canvas accounts.
class SyncToLMS

  # Meta-note to self: DONT worry about parsing things out into actual models, e.g. Program, User, Etc. But also don't go crazy testing
  # the stuff that will eventually be parsed and saved as models. We need to just get this working, so it's fine to have a slightly
  # hacky "translate this param to that param" between the APIs without involving local models to make it clean and build upon in this
  # iteration.

  def initialize
    @salesforce_api = SalesforceAPI.client
    @canvas_api = CanvasAPI.client
    @programs = {}
  end

  # Syncs all folks from the specific Salesforce Program to Canvas.
  def for_program(salesforce_program_id)
    @sync_mode = :program_sync
    @all_existing_course_enrollments = {}
    @all_existing_course_sections_by_name = {}

    # TODO: store the last time this was run for this course and in subsequent calls, pass that in as the last_modified_since parameter.
    participants = @salesforce_api.get_participants(salesforce_program_id)
    Rails.logger.debug("Processing #{participants.count} Salesforce Participants to sync to Canvas for salesforce_program_id = #{salesforce_program_id}")
    participants.each { |p| sync_participant(p) }
  end

  def for_contact(contact_id)
    @sync_mode = :contact_sync
    @all_existing_course_sections_by_name = {}

    participants = @salesforce_api.get_participants(nil, contact_id)
    Rails.logger.debug("Processing #{participants.count} Salesforce Participant objects to sync for contact_id = #{contact_id}")

    canvas_id = nil
    participants.each { |p| canvas_id = sync_participant(p) }
    canvas_id
  end

  # The logic for who get's sync'd is anyone with a ParticipantStatus == 'Enrolled'. If they have a CohortName
  # set, they are put in a Canvas Section with that name. If it's not set, they are put in a placeholder cohort
  # that corresponds to the day and time that their Learning Lab meets.
  #
  # Assumptions: there are no duplicate Participant objects and if they opt out or drop as a Candidate, the ParticipantStatus is
  # updated accordingly.
  def sync_participant(participant)
    # Parse the Salesforce Participant object
    first_name = participant['FirstName']
    last_name = participant['LastName']
    email = participant['Email']
    role = participant['Role'].to_sym
    program_id = participant['ProgramId']
    contact_id = participant['ContactId']
    #last_modified_date = participant['LastModifiedDate'] # TODO: implement me
    participant_status = participant['ParticipantStatus'] # E.g. 'Enrolled' 
    #candidate_status = participant['CandidateStatus']  # E.g. 'Fully Confirmed'
    student_id = participant['StudentId']
    #school_id = participant['SchoolId'] # This is the Salesforce ID for their school # TODO: implement me
    username = email # TODO: if they are nlu, their username isn't their email. it's "#{user_student_id}@nlu.edu"

    program = get_program(program_id)

    # Create or update the Canvas user account.
    canvas_user_id = nil
    existing_user = @canvas_api.find_user_in_canvas(email)
    if existing_user
      canvas_user_id = existing_user['id']
      Rails.logger.debug("Skipping Canvas account creation for existing canvas_user_id = #{canvas_user_id}")
      # TODO: the below was in the original code. This could be what causes us using many, many more DocuSign envelopes than necessary though.
      # Figure out how to implement this properly.
      # The DocuSign template could have changed after we first created the user with it. So update it for existing users.
      # update_user_in_canvas(user, :docusign_template_id => docusign_template_id)
    elsif participant_status == 'Enrolled'
      docusign_template_id = if role == :'Leadership Coach'
                               program.lc_docusign_template_id
                             else
                               program.docusign_template_id
                             end
      new_canvas_user = @canvas_api.create_user(first_name, last_name, username, email, contact_id, student_id, program.timezone, docusign_template_id)
      canvas_user_id = new_canvas_user['id']
      Rails.logger.debug("Created new canvas_user_id = #{canvas_user_id}")
    else
      Rails.logger.warn("Salesforce user with contact: #{contact_id} is not enrolled")
    end

    case participant_status
    when 'Enrolled'
      section_name = get_section_name(participant)
      enroll_user(canvas_user_id, program, role, section_name)
    when 'Dropped'
      drop_user_enrollment(canvas_user_id, program, role)
    when 'Completed'
      complete_user_enrollment(canvas_user_id)
    else
      Rails.logger.warn("Unrecognized Participant.Status sent from Salesforce: #{participant_status}. canvas_user_id = #{canvas_user_id}, contact_id = #{contact_id}")
    end

    # TODO: reimplement the following logic to sync their enrollment info
    # taken from salesforce_controller.rb in Join code
    # qr = lms.trigger_qualtrics_preparation(campaign.Target_Course_ID_In_LMS__c[0].to_i, campaign.Preaccelerator_Qualtrics_Survey_ID__c, campaign.Postaccelerator_Qualtrics_Survey_ID__c, additional_data)

    canvas_user_id
  end

  # Enroll or update their enrollment in the proper course and section
  def enroll_user(canvas_user_id, program, role, fellow_course_section_name)
    if role == :Fellow
      sync_course_enrollment(canvas_user_id, program.fellow_course_id, :StudentEnrollment, fellow_course_section_name)
    elsif role == :'Leadership Coach'
      sync_course_enrollment(canvas_user_id, program.fellow_course_id, :TaEnrollment, fellow_course_section_name)
      sync_course_enrollment(canvas_user_id, program.leadership_coach_course_id, :StudentEnrollment, program.leadership_coach_course_section_name)
    else
      Rails.logger.error("Unrecognized role = '#{role}' returned from Salesforce. Skipping Sync To LMS for Salesforce Participant = #{canvas_user_id}")
    end
  end

  def drop_user_enrollment(canvas_user_id, program, role)
    existing_fellow_course_enrollment = get_enrollment(canvas_user_id, program.fellow_course_id)
    if existing_fellow_course_enrollment 
      Rails.logger.debug("Cancelling enrollment for canvas_user_id = #{canvas_user_id} in course_id #{program.fellow_course_id} because they Dropped.")
      @canvas_api.cancel_enrollment(existing_fellow_course_enrollment)
    end

    if role == :'Leadership Coach'
      existing_lc_course_enrollment = get_enrollment(canvas_user_id, program.leadership_coach_course_id)
      if existing_lc_course_enrollment
        Rails.logger.debug("Cancelling enrollment for canvas_user_id = #{canvas_user_id} in course_id #{program.leadership_coach_course_id} because they Dropped.")
        @canvas_api.cancel_enrollment(existing_lc_course_enrollment)
      end
    end
  end

  def complete_user_enrollment(canvas_user_id)
    # NOOP right now. In the future, maybe we remove course access after the program completes and that would be implemented here.
  end

  # Syncs the Canvas enrollments for the given user in the given course, by unenrolling
  # from existing courses, if necessary, and enrolling them in the new course+section.
  #
  # Note: canvas_role = [:StudentEnrollment, :TaEnrollment, :DesignerEnrollment, :TeacherEnrollment]
  def sync_course_enrollment(canvas_user_id, course_id, canvas_role, section_name)
    section_name ||= 'Default Section'
    existing_enrollment = get_enrollment(canvas_user_id, course_id)
    section = get_section(course_id, section_name)
    unless section
      section = @canvas_api.create_section(course_id, section_name) 
      # Add it to the cache so that other folks being sync'ed to this section don't create dupes.
      @all_existing_course_sections_by_name[course_id][section['name']] = section
      Rails.logger.debug("Created new Section in Canvas course_id = #{course_id} called '#{section['name']}' with section_id = #{section['id']}")
    end
    section_id = section['id']

    if existing_enrollment.is_a? Array
      existing_enrollment = existing_enrollment.last
    end

    if existing_enrollment && existing_enrollment['course_section_id'] != section_id
      Rails.logger.debug("Moving canvas_user_id = #{canvas_user_id} in course_id = #{course_id} from section_id = #{existing_enrollment['course_section_id']} to a new one")
      @canvas_api.cancel_enrollment(existing_enrollment)
      existing_enrollment = nil
    end

    if existing_enrollment && existing_enrollment['type'].to_sym != canvas_role
      Rails.logger.debug("Re-enrolling canvas_user_id = #{canvas_user_id} in course_id = #{course_id} because their role changed from #{existing_enrollment['type']} to #{canvas_role}")
      @canvas_api.cancel_enrollment(existing_enrollment)
      existing_enrollment = nil
    end

    if existing_enrollment.nil?
      # They aren't enrolled properly, enroll them now
      @canvas_api.enroll_user_in_course(canvas_user_id, course_id, canvas_role, section_id)
      Rails.logger.debug("Enrolled canvas_user_id = #{canvas_user_id} in section_id = #{section_id}")
    end

    # Otherwise, the existing_enrollment passed all tests, we don't need to do anything

  end

  # If the CohortName isn't set, get their LL day/time schedule and use a placeholder section that we setup before
  # they are mapped to their real cohort in the 2nd or 3rd week.
  def get_section_name(participant)
    cohort_name = participant['CohortName']                   # E.g. SJSU Brian (Tues)
    cohort_schedule = participant['CohortScheduleDayTime']    # E.g. 'Monday, 7:00'
    cohort_name ||= cohort_schedule
  end

  def get_enrollment(canvas_user_id, course_id)
    if @sync_mode == :program_sync
      # Loads all enrollments for the course on the first call and caches that for future calls.
      unless @all_existing_course_enrollments[course_id]
        @all_existing_course_enrollments[course_id] = @canvas_api.get_enrollments(course_id)
      end
      @all_existing_course_enrollments[course_id].find { |enrollment| enrollment['user_id'] == canvas_user_id }
    elsif @sync_mode == :contact_sync
      enrolments = @canvas_api.get_user_enrollments(canvas_user_id, course_id)
      # Filter by course_id
      enrolments&.filter { |enrolment| enrolment['course_id']&.to_i.eql?(course_id&.to_i) }
    else
      raise "Unrecognized @sync_mode = #{@sync_mode}"
    end
  end

  # Loads all sections for the course on the first call and caches that for future calls.
  def get_section(course_id, section_name)
    unless @all_existing_course_sections_by_name[course_id]
      @all_existing_course_sections_by_name[course_id] = {}
      @canvas_api.get_sections(course_id).each { |section| @all_existing_course_sections_by_name[course_id][section['name']] = section }
    end
    @all_existing_course_sections_by_name[course_id][section_name]
  end

  # Loads the program info on the first call and caches it for future calls.
  def get_program(program_id)
    unless @programs[program_id]
      p = Program.new
      program_info = @salesforce_api.get_program_info(program_id)
      raise SalesforceAPI::SalesforceDataError.new("Missing 'Default_Timezone__c' data") unless program_info['Default_Timezone__c']
      p.attributes = {
        :name                                 => program_info['Name'],
        :salesforce_id                        => program_info['Id'],
        :salesforce_school_id                 => program_info['SchoolId'],
        :fellow_course_id                     => program_info['Target_Course_ID_in_LMS__c'].to_i,
        :leadership_coach_course_id           => program_info['LMS_Coach_Course_Id__c'].to_i,
        :leadership_coach_course_section_name => program_info['Section_Name_in_LMS_Coach_Course__c'],
        :timezone                             => program_info['Default_Timezone__c'].to_sym,
        :docusign_template_id                 => program_info['Docusign_Template_ID__c'],
        :pre_accelerator_qualtrics_survey_id  => program_info['Preaccelerator_Qualtrics_Survey_ID__c'],
        :post_accelerator_qualtrics_survey_id => program_info['Postaccelerator_Qualtrics_Survey_ID__c'],
        :lc_docusign_template_id              => program_info['LC_DocuSign_Template_ID__c']
      }
      @programs[program_id] = p
    end
    @programs[program_id]
  end

end
