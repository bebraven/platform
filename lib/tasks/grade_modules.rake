# This task might take some time to run, and use up a lot of memory, depending on how many Rise360ModuleInteraction
# records we need to process. We plan to schedule it to run once a day, in the middle of the night. If
# at some point we decide we need to calculate grades more frequently, we may need to optimize this
# task to be more memory- and/or time-efficient.

require 'module_grade_calculator'

namespace :grade do
  desc "grade modules"
  task modules: :environment do
    puts("### Running rake grade:modules - #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}")

    # Select the max id at the very beginning, so we can use it at the bottom to mark only things
    # before this as old. If we don't do this, we run the risk of marking things as old that we
    # haven't actually processed yet, causing students to get missing or incorrect grades.
    # With this constraint, there's a chance we might process things twice (e.g. if the heroku
    # app restarts in the middle of the task), but that would only result in us doing a little more
    # work, and still always giving everyone the correct grades.
    max_id = Rise360ModuleInteraction.maximum(:id)
    records = Rise360ModuleInteraction
      .select(:user_id, :activity_id, :verb, :canvas_course_id, :canvas_assignment_id)
      .where(new: true)
      .group(:user_id, :activity_id, :verb, :canvas_course_id, :canvas_assignment_id)

    Honeycomb.add_field('max_id', max_id)
    Honeycomb.add_field('records.length', records.length)
    puts "Processing #{records.length} grades for new interactions up to Rise360ModuleInteraction[id: #{max_id}]"

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

    # Initialize a map to cache assighment overrides.
    assignment_override_map = Hash.new

    # Compute.
    grades = Hash.new
    Honeycomb.start_span(name: 'rake:grade:modules:compute') do |span|
      filtered_records.each do |record|
        puts "Computing grade for: user_id = #{record.user_id}, canvas_course_id = #{record.canvas_course_id}, " \
             "canvas_assignment_id = #{record.canvas_assignment_id}, module activity_id = #{record.root_activity_id}"
        user = User.find(record.user_id)

        # Fetch and store assignment overrides, one Canvas API call per course/assignment.
        assignment_override_map[record.canvas_assignment_id] ||= CanvasAPI
          .client.get_assignment_overrides(record.canvas_course_id, record.canvas_assignment_id)

        grades[record.canvas_course_id] ||= Hash.new
        grades[record.canvas_course_id][record.canvas_assignment_id] ||= Hash.new
        grades[record.canvas_course_id][record.canvas_assignment_id][user.canvas_user_id] =
          "#{ModuleGradeCalculator.compute_grade(
            user.id,
            record.canvas_assignment_id,
            record.root_activity_id,
            assignment_override_map[record.canvas_assignment_id]
          )}%"
      end
    end

    Honeycomb.start_span(name: 'rake:grade:modules:update') do |span|
      # Send in batches.
      grades.keys.each do |canvas_course_id|
        grades[canvas_course_id].keys.each do |canvas_assignment_id|
          puts "Sending new grades to Canvas for canvas_course_id = #{canvas_course_id}, canvas_assignment_id = #{canvas_assignment_id}"
          grades_by_user_id = grades[canvas_course_id][canvas_assignment_id]
          CanvasAPI.client.update_grades(canvas_course_id, canvas_assignment_id, grades_by_user_id)
          Rise360ModuleInteraction.where(new: true, canvas_course_id: canvas_course_id, canvas_assignment_id:
              canvas_assignment_id).where('id <= ?', max_id).update_all(new: false)
        end
      end
    end

    puts("### Done running rake grade:modules - #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}")
  end
end
