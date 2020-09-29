
# TODO:
# This table is used to record the status of a Fellows attendance at an event for a course:
#  attendance_statuses: id, attendance_event_id, user_id, present, late (should only apply if marked present), reason (should only apply if marked absent)
class AttendanceStatus < ApplicationRecord
# TODO:  belongs_to :attendance_events
# TODO:  belongs_to :users

# TODO: validates what?

end
