class CourseMembership < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :course, -> {
    where(base_courses: { type: 'Course' })
  }, foreign_key: :base_course_id

  
  scope :current, -> { today = Date.today; where("start_date <= ?", today).where("end_date >= ? or end_date is null", today) }
  
  def current?
    today = Date.today
    start_date <= today && (end_date.nil? || end_date >= today)
  end
end
