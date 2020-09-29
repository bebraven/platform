
# This table represents an event (aka an LL of capstone event) where
# an attendance_status can be associated with that event for a given course or course_template.
#   attendance_events: id, name, canvas_assignment_id, canvas_course_id
#
class AttendanceEvent < ApplicationRecord
# TODO:  has_many :attendance_statuses

  validates :name, presence: true # TODO: do we event store this locally. It's needed when displaying this event, but it should match the Canvas assignment. Just pull from Canvas and manage it there?
  validates :canvas_assignment_id, presence: true # TODO: do we have this when inserting one of this from Lti Assignment Selection?
  validates :canvas_course_id, presence: true # TODO: do we have this when inserting one of this from Lti Assignment Selection?

  # TODO: the datetime of the event is different for different sections. Need to query canvas based on the section
  # that we care about to see the due_date

  # TODO: can we reliably clone these as part of cloning a canvas course and use the name (or something else) to find 
  # them and adjust the stored canvas_assignment_id and canvas_course_id ? I think so, but we'd prob want to try and do a PoC
  # there before implementing anything else in this HAX commit!!
end
