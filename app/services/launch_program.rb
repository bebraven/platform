# frozen_string_literal: true

class LaunchProgram
  def initialize(salesforce_program_id:, fellow_course_template_id:, fellow_course_name:, lc_course_template_id:, lc_course_name:)
    @salfesforce_program_id = salesforce_program_id
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

  # Raise exceptions from here so they can be handled in the controller.
  def run
    LaunchProgram.canvas_launch!(@fellow_course, @fellow_course_template)
    LaunchProgram.canvas_launch!(@lc_course, @lc_course_template)
  end

  def self.canvas_launch!(course, course_template)
    # Be reasonably sure copy_course is going to work before calling create_course, otherwise
    # you'll end up with a bunch of empty courses in Canvas.
    canvas_course_data = CanvasAPI.client.create_course(course.name)
    course.update!(canvas_course_id: canvas_course_data['id'])
    CanvasAPI.client.copy_course(course_template.canvas_course_id, course.canvas_course_id)
  end
end
