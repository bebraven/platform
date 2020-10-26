FactoryBot.define do
  # Represents an Assignment object returned from the canvas API
  # See: https://canvas.instructure.com/doc/api/assignments.html#method.assignments_api.index
  #
  # Important: this is meant to be built with FactoryBot.json(:canvas_assignment)
  factory :canvas_assignment, class: Hash do
    skip_create # This isn't stored in the DB.

    transient do
      sequence(:lti_launch_url) { |i| "https://platformweb/some/lti_launch/endpoint/#{i}" }
    end

    sequence(:id) 
    description { '<p>The text in the editor box</p>' }
    due_at { '2020-09-26T03:59:59Z' }
    unlock_at { nil }
    lock_at { nil }
    sequence(:points_possible) { |i| i.to_f }
    grading_type { 'points' }
    sequence(:assignment_group_id)
    created_at { "2020-10-14T16:25:09Z" } 
    updated_at { "2020-10-14T16:26:10Z" } 
    sequence(:position)
    omit_from_final_grade { false }
    allowed_attempts { -1 } # infinite
    sequence(:course_id)
    sequence(:name) {|i| "Example Assignment#{i}"}
    submission_types { ['external_tool'] }
    has_submitted_submissions { false }
    workflow_state { 'published' }
    sequence(:external_tool_tag_attributes) { |i| 
      { 
        'url' => lti_launch_url,
        'new_tab' => false,
        'resource_link_id' => "b4793177cdff4db60af282b4d9eb789ed2ccc3#{i}",
        'external_data' => '',
        'content_type' => 'ContextExternalTool', 
        'content_id' => i
      } 
    }
    muted { false }
    html_url { "https://braven.instructure.com/courses/#{course_id}/#{id}" }
    url { "https://braven.instructure.com/api/v1/courses/#{course_id}/external_tools/sessionless_launch?assignment_id=#{id}&launch_type=assessment" }
    has_overrides { false }
    overrides { nil }
    submissions_download_url { "https://braven.instructure.com/courses/#{course_id}/assignments/#{id}/submissions?zip=1" }

    initialize_with { attributes.stringify_keys }
  end
end

# Example:
#{
#  // the ID of the assignment
#  "id": 4,
#  // the name of the assignment
#  "name": "some assignment",
#  // the assignment description, in an HTML fragment
#  "description": "<p>Do the following:</p>...",
#  // The time at which this assignment was originally created
#  "created_at": "2012-07-01T23:59:00-06:00",
#  // The time at which this assignment was last modified in any way
#  "updated_at": "2012-07-01T23:59:00-06:00",
#  // the due date for the assignment. returns null if not present. NOTE: If this
#  // assignment has assignment overrides, this field will be the due date as it
#  // applies to the user requesting information from the API.
#  "due_at": "2012-07-01T23:59:00-06:00",
#  // the lock date (assignment is locked after this date). returns null if not
#  // present. NOTE: If this assignment has assignment overrides, this field will
#  // be the lock date as it applies to the user requesting information from the
#  // API.
#  "lock_at": "2012-07-01T23:59:00-06:00",
#  // the unlock date (assignment is unlocked after this date) returns null if not
#  // present NOTE: If this assignment has assignment overrides, this field will be
#  // the unlock date as it applies to the user requesting information from the
#  // API.
#  "unlock_at": "2012-07-01T23:59:00-06:00",
#  // whether this assignment has overrides
#  "has_overrides": true,
#  // (Optional) all dates associated with the assignment, if applicable
#  "all_dates": null,
#  // the ID of the course the assignment belongs to
#  "course_id": 123,
#  // the URL to the assignment's web page
#  "html_url": "https://...",
#  // the URL to download all submissions as a zip
#  "submissions_download_url": "https://example.com/courses/:course_id/assignments/:id/submissions?zip=1",
#  // the ID of the assignment's group
#  "assignment_group_id": 2,
#  // Boolean flag indicating whether the assignment requires a due date based on
#  // the account level setting
#  "due_date_required": true,
#  // Allowed file extensions, which take effect if submission_types includes
#  // 'online_upload'.
#  "allowed_extensions": ["docx", "ppt"],
#  // An integer indicating the maximum length an assignment's name may be
#  "max_name_length": 15,
#  // Boolean flag indicating whether or not Turnitin has been enabled for the
#  // assignment. NOTE: This flag will not appear unless your account has the
#  // Turnitin plugin available
#  "turnitin_enabled": true,
#  // Boolean flag indicating whether or not VeriCite has been enabled for the
#  // assignment. NOTE: This flag will not appear unless your account has the
#  // VeriCite plugin available
#  "vericite_enabled": true,
#  // Settings to pass along to turnitin to control what kinds of matches should be
#  // considered. originality_report_visibility can be 'immediate',
#  // 'after_grading', 'after_due_date', or 'never' exclude_small_matches_type can
#  // be null, 'percent', 'words' exclude_small_matches_value: - if type is null,
#  // this will be null also - if type is 'percent', this will be a number between
#  // 0 and 100 representing match size to exclude as a percentage of the document
#  // size. - if type is 'words', this will be number > 0 representing how many
#  // words a match must contain for it to be considered NOTE: This flag will not
#  // appear unless your account has the Turnitin plugin available
#  "turnitin_settings": null,
#  // If this is a group assignment, boolean flag indicating whether or not
#  // students will be graded individually.
#  "grade_group_students_individually": false,
#  // (Optional) assignment's settings for external tools if submission_types
#  // include 'external_tool'. Only url and new_tab are included (new_tab defaults
#  // to false).  Use the 'External Tools' API if you need more information about
#  // an external tool.
#  "external_tool_tag_attributes": null,
#  // Boolean indicating if peer reviews are required for this assignment
#  "peer_reviews": false,
#  // Boolean indicating peer reviews are assigned automatically. If false, the
#  // teacher is expected to manually assign peer reviews.
#  "automatic_peer_reviews": false,
#  // Integer representing the amount of reviews each user is assigned. NOTE: This
#  // key is NOT present unless you have automatic_peer_reviews set to true.
#  "peer_review_count": 0,
#  // String representing a date the reviews are due by. Must be a date that occurs
#  // after the default due date. If blank, or date is not after the assignment's
#  // due date, the assignment's due date will be used. NOTE: This key is NOT
#  // present unless you have automatic_peer_reviews set to true.
#  "peer_reviews_assign_at": "2012-07-01T23:59:00-06:00",
#  // Boolean representing whether or not members from within the same group on a
#  // group assignment can be assigned to peer review their own group's work
#  "intra_group_peer_reviews": false,
#  // The ID of the assignment’s group set, if this is a group assignment. For
#  // group discussions, set group_category_id on the discussion topic, not the
#  // linked assignment.
#  "group_category_id": 1,
#  // if the requesting user has grading rights, the number of submissions that
#  // need grading.
#  "needs_grading_count": 17,
#  // if the requesting user has grading rights and the
#  // 'needs_grading_count_by_section' flag is specified, the number of submissions
#  // that need grading split out by section. NOTE: This key is NOT present unless
#  // you pass the 'needs_grading_count_by_section' argument as true.  ANOTHER
#  // NOTE: it's possible to be enrolled in multiple sections, and if a student is
#  // setup that way they will show an assignment that needs grading in multiple
#  // sections (effectively the count will be duplicated between sections)
#  "needs_grading_count_by_section": [{"section_id":"123456","needs_grading_count":5}, {"section_id":"654321","needs_grading_count":0}],
#  // the sorting order of the assignment in the group
#  "position": 1,
#  // (optional, present if Sync Grades to SIS feature is enabled)
#  "post_to_sis": true,
#  // (optional, Third Party unique identifier for Assignment)
#  "integration_id": "12341234",
#  // (optional, Third Party integration data for assignment)
#  "integration_data": {"5678":"0954"},
#  // the maximum points possible for the assignment
#  "points_possible": 12.0,
#  // the types of submissions allowed for this assignment list containing one or
#  // more of the following: 'discussion_topic', 'online_quiz', 'on_paper', 'none',
#  // 'external_tool', 'online_text_entry', 'online_url', 'online_upload'
#  // 'media_recording'
#  "submission_types": ["online_text_entry"],
#  // If true, the assignment has been submitted to by at least one student
#  "has_submitted_submissions": true,
#  // The type of grading the assignment receives; one of 'pass_fail', 'percent',
#  // 'letter_grade', 'gpa_scale', 'points'
#  "grading_type": "points",
#  // The id of the grading standard being applied to this assignment. Valid if
#  // grading_type is 'letter_grade' or 'gpa_scale'.
#  "grading_standard_id": null,
#  // Whether the assignment is published
#  "published": true,
#  // Whether the assignment's 'published' state can be changed to false. Will be
#  // false if there are student submissions for the assignment.
#  "unpublishable": false,
#  // Whether the assignment is only visible to overrides.
#  "only_visible_to_overrides": false,
#  // Whether or not this is locked for the user.
#  "locked_for_user": false,
#  // (Optional) Information for the user about the lock. Present when
#  // locked_for_user is true.
#  "lock_info": null,
#  // (Optional) An explanation of why this is locked for the user. Present when
#  // locked_for_user is true.
#  "lock_explanation": "This assignment is locked until September 1 at 12:00am",
#  // (Optional) id of the associated quiz (applies only when submission_types is
#  // ['online_quiz'])
#  "quiz_id": 620,
#  // (Optional) whether anonymous submissions are accepted (applies only to quiz
#  // assignments)
#  "anonymous_submissions": false,
#  // (Optional) the DiscussionTopic associated with the assignment, if applicable
#  "discussion_topic": null,
#  // (Optional) Boolean indicating if assignment will be frozen when it is copied.
#  // NOTE: This field will only be present if the AssignmentFreezer plugin is
#  // available for your account.
#  "freeze_on_copy": false,
#  // (Optional) Boolean indicating if assignment is frozen for the calling user.
#  // NOTE: This field will only be present if the AssignmentFreezer plugin is
#  // available for your account.
#  "frozen": false,
#  // (Optional) Array of frozen attributes for the assignment. Only account
#  // administrators currently have permission to change an attribute in this list.
#  // Will be empty if no attributes are frozen for this assignment. Possible
#  // frozen attributes are: title, description, lock_at, points_possible,
#  // grading_type, submission_types, assignment_group_id, allowed_extensions,
#  // group_category_id, notify_of_update, peer_reviews NOTE: This field will only
#  // be present if the AssignmentFreezer plugin is available for your account.
#  "frozen_attributes": ["title"],
#  // (Optional) If 'submission' is included in the 'include' parameter, includes a
#  // Submission object that represents the current user's (user who is requesting
#  // information from the api) current submission for the assignment. See the
#  // Submissions API for an example response. If the user does not have a
#  // submission, this key will be absent.
#  "submission": null,
#  // (Optional) If true, the rubric is directly tied to grading the assignment.
#  // Otherwise, it is only advisory. Included if there is an associated rubric.
#  "use_rubric_for_grading": true,
#  // (Optional) An object describing the basic attributes of the rubric, including
#  // the point total. Included if there is an associated rubric.
#  "rubric_settings": "{"points_possible"=>12}",
#  // (Optional) A list of scoring criteria and ratings for each rubric criterion.
#  // Included if there is an associated rubric.
#  "rubric": null,
#  // (Optional) If 'assignment_visibility' is included in the 'include' parameter,
#  // includes an array of student IDs who can see this assignment.
#  "assignment_visibility": [137, 381, 572],
#  // (Optional) If 'overrides' is included in the 'include' parameter, includes an
#  // array of assignment override objects.
#  "overrides": null,
#  // (Optional) If true, the assignment will be omitted from the student's final
#  // grade
#  "omit_from_final_grade": true,
#  // Boolean indicating if the assignment is moderated.
#  "moderated_grading": true,
#  // The maximum number of provisional graders who may issue grades for this
#  // assignment. Only relevant for moderated assignments. Must be a positive
#  // value, and must be set to 1 if the course has fewer than two active
#  // instructors. Otherwise, the maximum value is the number of active instructors
#  // in the course minus one, or 10 if the course has more than 11 active
#  // instructors.
#  "grader_count": 3,
#  // The user ID of the grader responsible for choosing final grades for this
#  // assignment. Only relevant for moderated assignments.
#  "final_grader_id": 3,
#  // Boolean indicating if provisional graders' comments are visible to other
#  // provisional graders. Only relevant for moderated assignments.
#  "grader_comments_visible_to_graders": true,
#  // Boolean indicating if provisional graders' identities are hidden from other
#  // provisional graders. Only relevant for moderated assignments with
#  // grader_comments_visible_to_graders set to true.
#  "graders_anonymous_to_graders": true,
#  // Boolean indicating if provisional grader identities are visible to the final
#  // grader. Only relevant for moderated assignments.
#  "grader_names_visible_to_final_grader": true,
#  // Boolean indicating if the assignment is graded anonymously. If true, graders
#  // cannot see student identities.
#  "anonymous_grading": true,
#  // The number of submission attempts a student can make for this assignment. -1
#  // is considered unlimited.
#  "allowed_attempts": 2,
#  // Whether the assignment has manual posting enabled. Only relevant for courses
#  // using New Gradebook.
#  "post_manually": true,
#  // (Optional) If 'score_statistics' and 'submission' are included in the
#  // 'include' parameter and statistics are available, includes the min, max, and
#  // mode for this assignment
#  "score_statistics": null,
#  // (Optional) If retrieving a single assignment and 'can_submit' is included in
#  // the 'include' parameter, flags whether user has the right to submit the
#  // assignment (i.e. checks enrollment dates, submission types, locked status,
#  // attempts remaining, etc...). Including 'can submit' automatically includes
#  // 'submission' in the include parameter.
#  "can_submit": true
#}
