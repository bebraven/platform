# frozen_string_literal: true

# Represents an LTI score message sent to the API. See:
# https://canvas.instructure.com/doc/api/score.html
class LtiScore
  
  LTI_SCORE_SUBMISSION_URL_KEY = "https://canvas.instructure.com/lti/submission"

  module ActivityProgress
    INITIALIZED='Initialized'
    STARTED='Started'
    IN_PROGRESS='InProgress'
    SUBMITTED='Submitted'
    COMPLETED='Completed' 
  end
 
  module GradingProgress
    NOT_READY = 'NotReady'
    FAILED = 'Failed'
    PENDING = 'Pending'
    PENDING_MANUAL = 'PendingManual'
    FULLY_GRADED = "FullyGraded"
  end

  include ActivityProgress
  include GradingProgress

  # Generates an LtiScore that represents a new Project submission where
  # a Teaching Assitant or other staff must grade the project.
  def self.new_project_submission(canvas_user_id, submission_url)
    submission_data = {
      :new_submission => true,
      :submission_type => 'basic_lti_launch',
      :submission_data => submission_url
    }
    generate(canvas_user_id, SUBMITTED, PENDING_MANUAL, submission_data)
  end

  # Params:
  # userId: The lti_user_id or the Canvas user_id
  # scoreGiven: The Current score received in the tool for this line item and user, scaled to
  #             the scoreMaximum
  # scoreMaximum: Maximum possible score for this result; it must be present if scoreGiven is
  #               present.
  # comment: Comment visible to the student about this score.
  # activityProgress: Indicate to Canvas the status of the user towards the activity's completion.
  #                   Must be one of Initialized, Started, InProgress, Submitted, Completed
  # gradingProgress:  Indicate to Canvas the status of the grading process. A value of
  #                   PendingManual will require intervention by a grader. Values of NotReady,
  #                   Failed, and Pending will cause the scoreGiven to be ignored. FullyGraded
  #                   values will require no action. Possible values are NotReady, Failed, Pending,
  #                   PendingManual, FullyGraded
  def self.generate(user_id, activity_progress = COMPLETED, grading_progress = FULLY_GRADED, submission = nil, score_given = nil, score_maximum = nil, comment = nil)
    msg = {
      :userId => user_id.to_s,
      :timestamp => DateTime.now,
      :activityProgress => activity_progress,
      :gradingProgress => grading_progress,
    }
    msg[LTI_SCORE_SUBMISSION_URL_KEY] = submission if submission
    msg[:scoreGiven] = score_given if score_given
    msg[:scoreMaximum] = score_maximum if score_maximum
    msg[:comment] = comment if comment
    msg.to_json
  end
end
