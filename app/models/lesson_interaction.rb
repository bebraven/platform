# frozen_string_literal: true
class LessonInteraction < ApplicationRecord
  PROGRESSED = 'http://adlnet.gov/expapi/verbs/progressed'
  ANSWERED = 'http://adlnet.gov/expapi/verbs/answered'

  belongs_to :user
  validates :user, :activity_id, :verb, :canvas_course_id, :canvas_assignment_id, presence: true

  scope :for_user_and_activity, -> (user_id, activity_id) do
    where(
      "activity_id LIKE ? AND user_id = ?",
      "#{activity_id}%",
      user_id,
    )
  end

  def root_activity_id
    if verb == ANSWERED
      # Remove the /quiz_id/question_id part.
      # Activity IDs for Rise360 ANSWERED verbs *usually* look something like:
      #   http://OrDngAKqbvX4sCs0vBpsk-P1VXsst1vc_rise/quiz-id/question-id_timestamp
      # However, the "root" ID is user-controlled, so we can't guarante we won't
      # get something like this instead:
      #   http://a/bunch/of/things/quiz-id/question-id_timestamp
      # Because we can only rely on the end of the string being consistent, we
      # say here "starting at the end, remove up to the second slash". That will
      # always give us the root activity ID, regardless of what that root looks like.
      activity_id.split('/')[0..-3].join('/')
    else
      activity_id
    end
  end
end
