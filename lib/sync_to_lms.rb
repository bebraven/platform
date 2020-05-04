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
  end

  # Syncs all folks from Salesforce to Canvas for the specified course.
  def execute(course_id)
    @all_existing_course_enrollments = {}
    @all_existing_course_sections_by_name = {}
    @program = get_program(course_id)

    # TODO: store the last time this was run for this course and in subsequent calls, pass that in as the last_modified_since parameter.
    participants = @salesforce_api.get_participants(course_id)
    Rails.logger.debug("Processing #{participants.count} Salesforce Participants to sync to Canvas for course_id = #{course_id}")
    participants.each { |p| sync_participant(p) }
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
    salesforce_id = participant['ContactId']
    #last_modified_date = participant['LastModifiedDate'] # TODO: implement me
    section_name = participant['CohortName']
    participant_status = participant['ParticipantStatus'] # E.g. 'Enrolled' 
    #candidate_status = participant['CandidateStatus']  # E.g. 'Fully Confirmed'
    student_id = participant['StudentId']
    #school_id = participant['SchoolId'] # This is the Salesforce ID for their school # TODO: implement me
    username = email # TODO: if they are nlu, their username isn't their email. it's "#{user_student_id}@nlu.edu"

    # TODO: if the CohortName isn't set, get their LL day/time and map to the placeholder cohorts that we setup before
    # they are mapped to their real cohort in the 2nd or 3rd week.

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
      new_canvas_user = @canvas_api.create_user(first_name, last_name, username, email, salesforce_id, student_id, @program.timezone, @program.docusign_template_id)
      canvas_user_id = new_canvas_user['id']
      Rails.logger.debug("Created new canvas_user_id = #{canvas_user_id}")
    end

    case participant_status
    when 'Enrolled'
      enroll_user(canvas_user_id, role, section_name)
    when 'Dropped'
      drop_user_enrollment(canvas_user_id, role)
    when 'Completed'
      complete_user_enrollment(canvas_user_id)
    else
      Rails.logger.warn("Unrecognized Participant.Status sent from Salesforce: #{participant_status}. canvas_user_id = #{canvas_user_id}, salesforce_id = #{salesforce_id}")
    end

    # TODO: reimplement the following logic to sync their enrollment info
    # taken from salesforce_controller.rb in Join code
    # qr = lms.trigger_qualtrics_preparation(campaign.Target_Course_ID_In_LMS__c[0].to_i, campaign.Preaccelerator_Qualtrics_Survey_ID__c, campaign.Postaccelerator_Qualtrics_Survey_ID__c, additional_data)

  end

  # Enroll or update their enrollment in the proper course and section
  def enroll_user(canvas_user_id, role, fellow_course_section_name)
    if role == :Fellow
      sync_course_enrollment(canvas_user_id, @program.fellow_course_id, :StudentEnrollment, fellow_course_section_name)
    elsif role == :'Leadership Coach'
      sync_course_enrollment(canvas_user_id, @program.fellow_course_id, :TaEnrollment, fellow_course_section_name)
      sync_course_enrollment(canvas_user_id, @program.leadership_coach_course_id, :StudentEnrollment, @program.leadership_coach_course_section_name)
    else
      Rails.logger.error("Unrecognized role = '#{role}' returned from Salesforce. Skipping Sync To LMS for Salesforce Participant = #{salesforce_id}")
    end
  end

  def drop_user_enrollment(canvas_user_id, role)
    existing_fellow_course_enrollment = get_enrollment(canvas_user_id, @program.fellow_course_id)
    if existing_fellow_course_enrollment 
      Rails.logger.debug("Cancelling enrollment for canvas_user_id = #{canvas_user_id} in course_id #{@program.fellow_course_id} because they Dropped.")
      @canvas_api.cancel_enrollment(existing_fellow_course_enrollment)
    end

    if role == :'Leadership Coach'
      existing_lc_course_enrollment = get_enrollment(canvas_user_id, @program.leadership_coach_course_id)
      if existing_lc_course_enrollment
        Rails.logger.debug("Cancelling enrollment for canvas_user_id = #{canvas_user_id} in course_id #{@program.leadership_coach_course_id} because they Dropped.")
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
    existing_enrollment = get_enrollment(canvas_user_id, course_id)
    section = get_section(course_id, section_name)
    unless section
      section = @canvas_api.create_section(course_id, section_name) 
      # Add it to the cache so that other folks being sync'ed to this section don't create dupes.
      @all_existing_course_sections_by_name[course_id][section['name']] = section
      Rails.logger.debug("Created new Section in Canvas course_id = #{course_id} called '#{section['name']}' with section_id = #{section['id']}")
    end
    section_id = section['id']

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

  # Loads all enrollments for the course on the first call and caches that for future calls.
  def get_enrollment(canvas_user_id, course_id)
    unless @all_existing_course_enrollments[course_id]
      @all_existing_course_enrollments[course_id] = @canvas_api.get_enrollments(course_id)
    end
    @all_existing_course_enrollments[course_id].find { |enrollment| enrollment['user_id'] == canvas_user_id }
  end

  # Loads all sections for the course on the first call and caches that for future calls.
  def get_section(course_id, section_name)
    unless @all_existing_course_sections_by_name[course_id]
      @all_existing_course_sections_by_name[course_id] = {}
      @canvas_api.get_sections(course_id).each { |section| @all_existing_course_sections_by_name[course_id][section['name']] = section }
    end
    @all_existing_course_sections_by_name[course_id][section_name]
  end

  def get_program(course_id)
    p = Program.new
    program_info = @salesforce_api.get_program_info(course_id)
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
      :post_accelerator_qualtrics_survey_id => program_info['Postaccelerator_Qualtrics_Survey_ID__c']
    }
    p
  end

end
