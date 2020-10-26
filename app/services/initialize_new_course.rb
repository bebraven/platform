# frozen_string_literal: true
require 'canvas_api'

# Responsible for initializing a new Canvas course:
# 1. creates the initial Canvas Sections based on the information in Salesforce
# 2. creates local projects, modules, etc for those found in the Canvas course
#
# This is mostly used after the New Program Launch creates a fresh Canvas course
# from a Course Template, but it may be used to point at a new course that we've manually
# setup in Canvas that is intended to be used as a new Course Template.
#
# Note: we discussed having the platform app be the place where all actions that required 
# us to store information in our local database would go through a platform Course Management
# UI and then relying on the local database information to reconcile and populate newly launched
# courses. We still want to move in the direction of having some key actions, such as creating
# a new LTI linked Canvas assignment (e.g. a Project) be done from the platform UI so that we
# have more programmatic control of what happens, such as creating a resourceId for the LineItem
# so that we can uniquely identify an LTI linked resource after a course is copied in Canvas and
# the assignment IDs change, but we don't want to completely re-build all the Canvas UI stuff so
# folks will still be doing stuff in Canvas which means they could take an action that doesn't match
# our local database information (such as changing the title of an assignment), so the approach we're
# moving towards is having this be able to both setup and sync the local database information from 
# the Canvas course information.
class InitializeNewCourse

  InitializeNewCourseError = Class.new(StandardError)

  def initialize(new_course, section_names)
    @new_course = new_course
    @section_names = section_names
  end

  def run
    canvas_assignment_ids = initialize_assignments()
    canvas_section_ids = create_sections(canvas_assignment_ids)

    # Add an AssignmentOverride date object to each assignment for each section so that 
    # the Edit Assignment Dates page shows the sections.
    CanvasAPI.client.create_assignment_overrides(@new_course.canvas_course_id, canvas_assignment_ids, canvas_section_ids)
  end

private

  # Grab the list of assignments from the new launched course. Look through them and for LTI assignments,
  # parse out the existing LTI launch URL, look up the resource (e.g. Project/Module/Survey/etc) that is 
  # being launched and associate it with the new base_course as well. Then update the Canvas 
  # assignment's launch URL to launch the newly associated resource. 
  def initialize_assignments
    canvas_assignment_ids = []
    canvas_assignments = CanvasAPI.client.get_assignments(@new_course.canvas_course_id)

    canvas_assignments.each do |ca|
      canvas_assignment_id = ca['id']
      canvas_assignment_ids << canvas_assignment_id

      lti_launch_url = parse_lti_launch_url(ca)
      if lti_launch_url
        initialize_lti_launch_resource(lti_launch_url, canvas_assignment_id)
      else
        Rails.logger.debug("Skipping Canvas Assignment[#{canvas_assignment_id}] - not an LTI linked assignment")
      end
    end

    canvas_assignment_ids
  end

  def initialize_lti_launch_resource(lti_launch_url, canvas_assignment_id)
    new_launch_url = nil

    # TODO: Instead of going this route of parsing the URL, the plan is to move LTI selection linking to a platform UI 
    # and do it programatically, linking everything up using a resourceId in the LineItem API.
    # See: https://app.asana.com/0/1174274412967132/1198900743766613
    course_template_content_version = BaseCourseCustomContentVersion.find_by_url(lti_launch_url) 
    if course_template_content_version
      if course_template_content_version.base_course.is_a? CourseTemplate
        new_launch_url = create_new_custom_content_resource(course_template_content_version, canvas_assignment_id)
        Rails.logger.debug("Updating Canvas Assignment[#{canvas_assignment_id}] - changing LTI launch URL to: #{new_launch_url}")
        CanvasAPI.client.update_assignment_lti_launch_url(@new_course.canvas_course_id, canvas_assignment_id, new_launch_url)
      else
        raise InitializeNewCourseError, "BaseCourseCustomContentVersion #{course_template_content_version.inspect} is not a CourseTemplate. " \
                                        "Only initializing from cloned templates is supported"
      end
    else 
      # Keep in mind that there may be LTI assignments for other providers, like Google or something, that we should skip.
      Rails.logger.debug("Skipping Canvas Assignment[#{canvas_assignment_id}] - it's an LTI linked assignment that doesn't need adjustment")
    end

  end

  def create_new_custom_content_resource(old_course_custom_content_version, canvas_assignment_id)
    if old_course_custom_content_version.base_course_id == @new_course.canvas_course_id
      raise InitializeNewCourseError, "Canvas Assignment[#{canvas_assignment_id}] is already associated with #{@new_course}"
    end

    new_cccv = BaseCourseCustomContentVersion.create!(
      base_course: @new_course,
      custom_content_version: old_course_custom_content_version.custom_content_version,
      canvas_assignment_id: canvas_assignment_id
    )

    new_launch_url = Rails.application.routes.url_helpers
      .new_base_course_custom_content_version_project_submission_url(new_cccv, :protocol => 'https')
  end

  def parse_lti_launch_url(canvas_assignment)
    canvas_assignment.dig('external_tool_tag_attributes', 'url')
  end

  def create_sections(canvas_assignment_ids)
    canvas_section_ids = []
    @section_names.each do |sname|
      cs = CanvasAPI.client.create_lms_section(course_id: @new_course.canvas_course_id, name: sname) 
      canvas_section_ids << cs.id
      ps = Section.create!(name: cs.name, base_course_id: @new_course.id, canvas_section_id: cs.id)      
    end
    canvas_section_ids
  end

end
