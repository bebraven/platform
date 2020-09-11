# frozen_string_literal: true

class LessonGradeCalculator

  LESSON_ENGAGEMENT_WEIGHT = 0.5

  # Relative weights for lesson grading
  def self.grade_weights
    {
      lesson_engagement: LESSON_ENGAGEMENT_WEIGHT,
      mastery_quiz: 1.0 - LESSON_ENGAGEMENT_WEIGHT,
    }
  end

  # Returns [0, 100] for user's total grade for a lesson.
  # Note: this ignores "new" on LessonInteraction and computes the grade from 
  # all of the records for the user and the lesson.
  # The caller should do any logic to determine whether the computation is 
  # necessary. For an example, see:
  #   lib/tasks/grade_lessons.rake
  def self.compute_grade(user_id, activity_id)
    interactions = LessonInteraction.for_user_and_activity(
      user_id,
      activity_id,
    )

    engagement_grade = grade_lesson_engagement(
      interactions.where(verb: LessonInteraction::PROGRESSED),
    )

    quiz_grade = grade_mastery_quiz(
      interactions.where(verb: LessonInteraction::ANSWERED),
      LessonContent.find_by(activity_id: activity_id).quiz_questions,
    )

    (
      grade_weights[:lesson_engagement] * engagement_grade + 
      grade_weights[:mastery_quiz] * quiz_grade
    )
  end

  # Returns [0, 100] for user's progress in a lesson
  def self.grade_lesson_engagement(interactions)
    interactions.maximum(:progress) || 0
  end

  # Returns [0, 100] for number of questions user got right out of the
  # questions in the lesson
  def self.grade_mastery_quiz(interactions, total_questions)
    most_recent = interactions
      .group(activity_id_without_timestamp)
      .maximum(:created_at)
      .to_h
      .values

    # Number of correct answers from most recent interactions
    correct_answers = interactions
      .where(
        created_at: most_recent,
        success: true,
      )
      .count

    100 * (correct_answers.to_f / total_questions.to_f)
  end

  # Returns SQL that strips off _<timestamp> from the activity_id
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
