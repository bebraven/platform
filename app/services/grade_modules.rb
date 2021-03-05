# frozen_string_literal: true

# Grades all Rise360 modules in all "running" courses, for all users.
# This is a class only to follow convention from the rest of our
# services. There is no state maintained in the class between runs.
# This code was refactored out of a rake task and into a service in
# order to make it easier to test. See lib/tasks/grade_modules.rake
# for usage.

require 'time'
require 'module_grade_calculator'

class GradeModules
  def initialize
  end

  def run
    Honeycomb.start_span(name: 'GradeModules.run') do |span|
      # From the list of "running" "programs" in Salesforce, fetch a list of "accelerator"
      # (non-LC) courses.
      # TODO: Remember to swap this hardcoded Highlander stuff out when we switch to prod.
      programs = SalesforceAPI.client.get_current_and_future_accelerator_programs
      canvas_course_ids = programs['records']&.map { |r| r['Highlander_Accelerator_Course_ID__c'] }
      span.add_field('canvas_course_ids', canvas_course_ids)

      # Eliminate courses with no module interactions, and exit early if that
      # leaves us with an empty list.
      courses = Course.where(canvas_course_id: canvas_course_ids)
        .filter { |c| Rise360ModuleInteraction.where(canvas_course_id: c.canvas_course_id).exists? }
      span.add_field('courses.count', courses.count)
      if courses.empty?
        puts "Exit early: no accelerator courses with interactions"
        return
      end

      # From the remaining courses, compute grades for all users.
      courses.each do |course|
        Honeycomb.start_span(name: 'GradeModules.run.course') do |span|
          # We're doing some less-readable queries here because they're drastically
          # more efficient than using the more-readable model associations would be.
          sections = Section.select(:id).where(course: course)
          roles = Role.select(:id).where(resource: sections)
          # We're loading all the User IDs into memory right now, so keep an eye out
          # if this needs to be batched or something.
          # NOTE: Don't copy this UserRole code anywhere else unless you *really* need the performance.
          # TODO: Can this be .where.group.pluck?
          user_ids = UserRole.select(:user_id).where(role: roles).group(:user_id).map { |ur| ur.user_id }

          canvas_assignment_ids = CourseRise360ModuleVersion
            .where(course: course)
            .pluck(:canvas_assignment_id) 

          span.add_field('course.id', course.id)
          span.add_field('course.canvas_course_id', course.canvas_course_id)
          span.add_field('users.count', user_ids.count)
          span.add_field('assignments.count', canvas_assignment_ids.count)

          canvas_assignment_ids.each do |canvas_assignment_id|
            # Initialize map of grades[canvas_user_id] = 'X%'.
            grades = Hash.new

            # Skip assignments with zero interactions; they probably haven't opened yet.
            unless Rise360ModuleInteraction.where(canvas_assignment_id: canvas_assignment_id).exists?
              puts "Skip canvas_assignment_id = #{canvas_assignment_id}; no interactions"
              next
            end

            # Fetch assignment overrides, one Canvas API call per course/assignment.
            assignment_overrides = CanvasAPI.client.get_assignment_overrides(
              course.canvas_course_id,
              canvas_assignment_id
            )

            # Select the max id before starting grading, so we can use it at the bottom to mark only things
            # before this as old. If we don't do this, we run the risk of marking things as old that we
            # haven't actually processed yet, causing students to get missing or incorrect grades.
            # NOTE: the `new` column should only be considered an estimate with +/- 1 day resolution.
            max_id = Rise360ModuleInteraction.maximum(:id)

            # All users in the course, even if they haven't interacted with this assignment.
            user_ids.each do |user_id|
              # If we're before the due date, and there are no *new* interactions, skip this user.
              due_date = Time.parse(ModuleGradeCalculator.due_date_for_user(user_id, assignment_overrides))
              interactions = Rise360ModuleInteraction.where(
                user_id: user_id,
                canvas_assignment_id: canvas_assignment_id,
                new: true,
              )
              # Note since we only call exists?, the slow `select *` query implied above never actually runs.
              if interactions.exists? && due_date < Time.utc.now
                puts "Skip user_id = #{user_id}, canvas_assignment_id = #{canvas_assignment_id}; " \
                    "no interactions and assignment isn't due yet"
                next
              end

              # If we're before the due date and there are new interactions, grade.
              # If we're after the due date, grade regardless of interactions, so
              # people who skipped this module get auto-zero grades in Canvas.

              puts "Computing grade for: user_id = #{user_id}, canvas_course_id = #{course.canvas_course_id}, " \
                  "canvas_assignment_id = #{canvas_assignment_id}"

              user = User.find(user_id)
              grades[user.canvas_user_id] =
                "#{ModuleGradeCalculator.compute_grade(
                  user_id,
                  canvas_assignment_id,
                  assignment_overrides
                )}%"
            end

            # Send grades to Canvas, one API call per course/assignment.
            puts "Sending new grades to Canvas for canvas_course_id = #{course.canvas_course_id}, canvas_assignment_id = #{canvas_assignment_id}"
            CanvasAPI.client.update_grades(course.canvas_course_id, canvas_assignment_id, grades)

            # Mark an *estimate* of the consumed interactions as `new: false`.
            # Some interactions used to calculate grades may not be included in this list.
            Rise360ModuleInteraction.where(
              new: true,
              canvas_course_id: course.canvas_course_id,
              canvas_assignment_id: canvas_assignment_id
            ).where('id <= ?', max_id).update_all(new: false)
          end
        end
      end
    end
  end
end
