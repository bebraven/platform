class Course < BaseCourse
  has_many :sections, foreign_key: :base_course_id
end
