# frozen_string_literal: true

class ModuleGradeCalculator
  ModuleGradeCalculatorError = Class.new(StandardError)

  # Relative weights for module grading.
  # Must add up to 1.0.
  def self.grade_weights
    {
      module_engagement: 0.4,
      mastery_quiz: 0.4,
      on_time: 0.2,
    }
  end

  # Returns [0, 100] for user's total grade for a module.
  # Note: this ignores "new" on Rise360ModuleInteraction and computes the grade from
  # all of the records for the user and the module.
  # The caller should do any logic to determine whether the computation is
  # necessary. For an example, see:
  #   lib/tasks/grade_modules.rake
  def self.compute_grade(user_id, canvas_assignment_id, assignment_overrides)
    Honeycomb.start_span(name: 'ModuleGradeCalculator.compute_grade') do |span|
      # Note: If a content designer publishes a new Rise360 package to the same
      # assignment, all old interactions are technically invalidated. But we
      # can't easily detect that here, so make sure outdated interactions are
      # handled elsewhere in the Rise360Module-related code.
      interactions = Rise360ModuleInteraction.where(
        canvas_assignment_id: canvas_assignment_id,
        user_id: user_id,
      )

      # If there are no interactions, exit early with a zero grade.
      # exists? is the fastest check when records aren't preloaded.
      return 0 unless interactions.exists?

      # Figure out which due date applies to this user.
      due_date = due_date_for_user(user_id, assignment_overrides)

      # Start computing grades.
      progressed_interactions = interactions.where(verb: Rise360ModuleInteraction::PROGRESSED)

      engagement_grade = grade_module_engagement(progressed_interactions)
      on_time_grade = grade_completed_on_time(progressed_interactions, due_date)

      # Note: a Rise360 package has the same activity ID when you update it and
      # export it again. This means, we can have multiple Rise360ModuleVersions with
      # the same activity ID. That's why we use the canvas_assignment_id to find the
      # the correct version.
      crmv = CourseRise360ModuleVersion.find_by!(canvas_assignment_id: canvas_assignment_id)
      rmv = Rise360ModuleVersion.find(crmv.rise360_module_version_id)
      total_quiz_questions = rmv.quiz_questions

      if total_quiz_questions && total_quiz_questions > 0
        quiz_grade = grade_mastery_quiz(
          interactions.where(verb: Rise360ModuleInteraction::ANSWERED),
          total_quiz_questions,
        )

        (
          grade_weights[:module_engagement] * engagement_grade +
          grade_weights[:mastery_quiz] * quiz_grade +
          grade_weights[:on_time] * on_time_grade
        )
      else
        # If there are no mastery questions, fold the mastery weight in with the engagement
        # weight, so that engagement is just worth more.
        (
          (grade_weights[:module_engagement] + grade_weights[:mastery_quiz]) * engagement_grade +
          grade_weights[:on_time] * on_time_grade
        )
      end
    end
  end

  # Return the due date for this user, taking into account both
  # section-level and user-level overrides, and choosing the *latest*
  # applicable date. Dates are whatever Canvas API returns, which at the
  # time of this writing has been tested to be UTC timestamp strings.
  def self.due_date_for_user(user_id, assignment_overrides)
    user = User.find(user_id)

    # Look for section overrides.
    # We don't bother limiting the user's section IDs to sections in this course,
    # because there won't be sections from other courses in the assignment
    # overrides, and we would have to pass in the course ID to compute_grade.
    canvas_section_ids = user.sections.map { |s| s.canvas_section_id }
    section_overrides = assignment_overrides.filter { |o| canvas_section_ids.include? o['course_section_id'] }

    # Then, look for user-specific overrides.
    user_overrides = assignment_overrides.filter { |o| o['student_ids']&.include? user.canvas_user_id }

    # Return the latest due date.
    [
      section_overrides,
      user_overrides,
    ].flatten.map { |o| o['due_at'] }.max
  end

  # Returns [0, 100] for user's progress in a module.
  def self.grade_module_engagement(interactions)
    interactions.maximum(:progress) || 0
  end

  # Returns [0, 100] for number of questions user got right out of the
  # questions in the module.
  def self.grade_mastery_quiz(interactions, total_questions)
    if total_questions.nil? || total_questions.zero?
      raise ModuleGradeCalculatorError, "Error grading mastery quizzes. No questions found. (total_questions = #{total_questions})"
    end

    most_recent = interactions
      .group(activity_id_without_timestamp)
      .maximum(:created_at)
      .to_h
      .values

    # Number of correct answers from most recent interactions.
    correct_answers = interactions
      .where(
        created_at: most_recent,
        success: true,
      )
      .count

    100 * (correct_answers.to_f / total_questions.to_f)
  end

  # Returns 0 *or* 100, representing whether the user reached 100%
  # progression before the due date.
  def self.grade_completed_on_time(interactions, due_date)
    on_time_progress = interactions.where('created_at <= ?', due_date)
      .order(:created_at)
      .last
      &.progress

    if on_time_progress.nil? or on_time_progress < 100
      0
    else
      100
    end
  end

  # Returns SQL that strips off _<timestamp> from the activity_id.
  def self.activity_id_without_timestamp
    # The activity_id for ANSWERED interactions have the format:
    #   MY_ACTIVITY_ID/some_unique_quiz_id/some_unique_question_id_timestamp

    # We need to reverse the activity_id to find the final _ character that
    # precedes the timestamp
    activity_id = "REVERSE(activity_id)"

    # This gives us the index of _ before <timestamp>
    idx = "POSITION('_' IN #{activity_id})"

    # This strips off _<timestamp> from the activity_id
    substring = "SUBSTRING(#{activity_id}, #{idx} + 1)"

    # Remember we were operating on the reversed activity_id, so flip it around
    # to make it human readable again
    "REVERSE(#{substring})"
  end
end
