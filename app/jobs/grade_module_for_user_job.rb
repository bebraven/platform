# frozen_string_literal: true

require 'module_grade_calculator'
require 'canvas_api'

class GradeModuleForUserJob < ApplicationJob
  queue_as :default

  def perform(user, canvas_course_id, canvas_assignment_id, activity_id)

    # TODO: only grade Modules and not things in the LC Playbook b/c it generates
    # email notifications and it's weird.  We probably still want to grade LCs and staff
    # in Modules just so they can test it out though:
    # https://app.asana.com/0/1174274412967132/1199946751486950

    Honeycomb.start_span(name: 'GradeModuleForUserJob.perform') do |span|
      span.add_field('grade_module_for_user_job.user_id', user.id)
      span.add_field('grade_module_for_user_job.canvas_course_id', canvas_course_id)
      span.add_field('grade_module_for_user_job.canvas_assignment_id', canvas_assignment_id)
      span.add_field('grade_module_for_user_job.activity_id', activity_id)

      # Select the max id at the very beginning, so we can use it at the bottom to mark only things
      # before this as old. If we don't do this, we run the risk of marking things as old that we
      # haven't actually processed yet, causing students to get missing or incorrect grades.
      max_id = Rise360ModuleInteraction.maximum(:id)

      # Fetch assignment overrides.
      assignment_overrides = CanvasAPI.client.get_assignment_overrides(
        canvas_course_id,
        canvas_assignment_id
      )

      grade = "#{ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, activity_id, assignment_overrides)}%"

      span.add_field('grade_module_for_user_job.grade', grade)
      Rails.logger.info("Graded finished Rise360ModuleVersion[user_id = #{user.id}, canvas_course_id = #{canvas_course_id}, " \
        "canvas_assignment_id = #{canvas_assignment_id}, activity_id = '#{activity_id}'] " \
        "- computed grade = #{grade}")

      result = CanvasAPI.client.update_grade(canvas_course_id, canvas_assignment_id, user.canvas_user_id, grade)

      Rails.logger.debug(result)

      Rise360ModuleInteraction.where(
        new: true,
        user: user,
        canvas_course_id: canvas_course_id,
        canvas_assignment_id: canvas_assignment_id,
      ).where('id <= ?', max_id).update_all(new: false)
    end
  end

end
