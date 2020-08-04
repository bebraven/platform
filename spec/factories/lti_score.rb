# See: https://canvas.instructure.com/doc/api/score.html
FactoryBot.define do

  # Create JSON with FactoryBot.json(:lti_score)
  factory :lti_score, class: Hash do

    # The lti_user_id or the Canvas user_id
    userId { 50 }
    # The Current score received in the tool for this line item and user, scaled to
    # the scoreMaximum
    scoreGiven { 50 }
    # Maximum possible score for this result; it must be present if scoreGiven is
    # present.
    scoreMaximum { 50 }
    # Comment visible to the student about this score.
    comment { "some comment on the grade" }
    # Date and time when the score was modified in the tool. Should use subsecond
    # precision.
    timestamp { "2017-04-16T18:54:36.736+00:00" }
    # Indicate to Canvas the status of the user towards the activity's completion.
    # Must be one of Initialized, Started, InProgress, Submitted, Completed
    activityProgress { "Completed" }
    # Indicate to Canvas the status of the grading process. A value of
    # PendingManual will require intervention by a grader. Values of NotReady,
    # Failed, and Pending will cause the scoreGiven to be ignored. FullyGraded
    # values will require no action. Possible values are NotReady, Failed, Pending,
    # PendingManual, FullyGraded
    gradingProgress { "FullyGraded" }

    initialize_with { attributes.stringify_keys }
  end

  factory :lti_score_response, class: Hash do
    resultUrl { 'https://example.canvas.domain/api/lti/courses/55/line_items/15/results/1' }
    initialize_with { attributes.stringify_keys }
  end
end
