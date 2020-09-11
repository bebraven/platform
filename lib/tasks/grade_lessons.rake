# This task might take some time to run, and use up a lot of memory, depending on how many LessonInteraction
# records we need to process. We plan to schedule it to run once a day, in the middle of the night. If
# at some point we decide we need to calculate grades more frequently, we may need to optimize this
# task to be more memory- and/or time-efficient.

require 'lesson_grade_calculator'

namespace :grade do
  desc "grade lessons"
  task lessons: :environment do
    # Select the max id at the very beginning, so we can use it at the bottom to mark only things
    # before this as old. If we don't do this, we run the risk of marking things as old that we
    # haven't actually processed yet, causing students to get missing or incorrect grades.
    # With this constraint, there's a chance we might process things twice (e.g. if the heroku
    # app restarts in the middle of the task), but that would only result in us doing a little more
    # work, and still always giving everyone the correct grades.
    max_id = LessonInteraction.maximum(:id)
    records = LessonInteraction
      .select(:user_id, :activity_id, :verb, :canvas_course_id, :canvas_assignment_id)
      .where(new: true)
      .group(:user_id, :activity_id, :verb, :canvas_course_id, :canvas_assignment_id)

    Honeycomb.add_field('max_id', max_id)
    Honeycomb.add_field('records.length', records.length)

    exit if records.empty?

    # Filter duplicate quiz activity_ids, so we only compute grades once for each (user,activity) pair.
    # It doesn't matter which record we pick when we discard these "duplicates", because the info we
    # care about (canvas course id, canvas assignment id, user id, root activity id) will always
    # be the same on each.
    filtered_records = records.uniq {
      |record| [ record.user_id, record.root_activity_id ]
    }

    # Remove the reference to the extra records. Maybe the GC will delete them for us?
    records = nil

    # Compute.
    grades = Hash.new
    Honeycomb.start_span(name: 'rake:grade:lessons:compute') do |span|
      filtered_records.each do |record|
        user = User.find(record.user_id)
        grades[record.canvas_course_id] ||= Hash.new
        grades[record.canvas_course_id][record.canvas_assignment_id] ||= Hash.new
        grades[record.canvas_course_id][record.canvas_assignment_id][user.canvas_id] = "#{LessonGradeCalculator.compute_grade(user.id, record.root_activity_id)}%"
      end
    end

    Honeycomb.start_span(name: 'rake:grade:lessons:update') do |span|
      # Send in batches.
      grades.keys.each do |canvas_course_id|
        grades[canvas_course_id].keys.each do |canvas_assignment_id|
          grades_by_user_id = grades[canvas_course_id][canvas_assignment_id]
          CanvasAPI.client.update_lesson_grades(canvas_course_id, canvas_assignment_id, grades_by_user_id)
          LessonInteraction.where(new: true, canvas_course_id: canvas_course_id, canvas_assignment_id:
              canvas_assignment_id).where('id <= ?', max_id).update_all(new: false)
        end
      end
    end
  end
end
