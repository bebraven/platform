# frozen_string_literal: true

class LaunchProgram
  LaunchProgramError = Class.new(StandardError)

  def initialize(salesforce_program_id, fellow_course_template_id, fellow_course_name, lc_course_template_id, lc_course_name)

    set_salesforce_vars(salesforce_program_id)

    @fellow_course_template = CourseTemplate.find(fellow_course_template_id)
    @fellow_course = Course.create!(
      name: fellow_course_name,
      course_resource: @fellow_course_template.course_resource
    )

    @lc_course_template = CourseTemplate.find(lc_course_template_id)
    @lc_course = Course.create!(
      name: lc_course_name,
    )
  end

  def run
    # Kick off both launches before we start waiting on them.
    fellow_launch_response = LaunchProgram.canvas_launch!(@fellow_course, @fellow_course_template)
    lc_launch_response = LaunchProgram.canvas_launch!(@lc_course, @lc_course_template)

    LaunchProgram.after_canvas_launch_completes!(fellow_launch_response) do
      InitializeNewCourse.new(@fellow_course, @fellow_course_section_names).run
    end

    LaunchProgram.after_canvas_launch_completes!(lc_launch_response) do
      InitializeNewCourse.new(@lc_course, @lc_course_section_names).run
    end
  end

  def self.canvas_launch!(course, course_template)
    # Be reasonably sure copy_course is going to work before calling create_course, otherwise
    # you'll end up with a bunch of empty courses in Canvas.
    canvas_course_data = CanvasAPI.client.create_course(course.name)
    course.update!(canvas_course_id: canvas_course_data['id'])
    CanvasAPI.client.copy_course(course_template.canvas_course_id, course.canvas_course_id)
  end

  def self.after_canvas_launch_completes!(launch_response, &block)
    response = launch_response
    progress_url = response['progress_url']
    start_time = Time.now
    while (response['workflow_state'] != 'completed' && response['workflow_state'] != 'failed')
      raise LaunchProgramError, "Canvas course copy failed. See: #{response['migration_issues_url']}" if response['workflow_state'] == 'failed'
      raise LaunchProgramError, 'Canvas course copy timed out after 3 minutes' if (Time.now - start_time) > 3.minutes # Fail safe so this doesn't poll forever.

      sleep 5.seconds

      response = CanvasAPI.client.get_copy_course_status(progress_url)
    end
    block.call
  end

private

  def set_salesforce_vars(salesforce_program_id)
    # TODO: Ideally, we would validate the Program info, like that there are Cohort Schedules and the "Coach Course Section Name" field is set,
    # at the time we're launching it instead of as part of the background job (where this is run). That way we can give immediate feedback if they're trying
    # to launch a program that has not been setup properly with the info we need to be able to launch it. This makes me wonder if we
    # should be introducing back a local platform Program model that represents the mapping of all the program related stuff. E.g.
    # we could use it to map LC to Accelerator courses. We could store the Cohort and Cohort Schedule names and use them to do the sync
    # logic when there are new ones or changes. We could store the state of the program, whether it's active or not, so that we can filter out
    # access to old content for returning LCs or Fellows who drop but come back for a future run. E.g current LCs shouldn't see attendance for
    # for attendance assignments for previous semesters event though they are in those sections.
    #
    # If we did that, then we could create the Program active record before launching the job which does this validation in the main UI
    # and then pass it to the job using a GlobalID parameter: https://edgeguides.rubyonrails.org/active_job_basics.html#globalid
    # Task to track: https://app.asana.com/0/1174274412967132/1198877695027085

    @salesforce_program = sf_client.find_program(id: salesforce_program_id)
    if @salesforce_program.leadership_coach_course_section_name.blank?
      raise LaunchProgramError, '''Section Name in LMS Coach Course'' Salesforce field not set on Program'
    end

    @lc_course_section_names = [ @salesforce_program.leadership_coach_course_section_name ]
    @fellow_course_section_names = sf_client.get_cohort_schedule_section_names(salesforce_program_id)

    if @fellow_course_section_names.blank?
      raise LaunchProgramError, 'No Cohort Schedules found for this Salesforce Program. Make sure those are setup first.'
    end
  end

  def sf_client
    SalesforceAPI.client
  end

end
