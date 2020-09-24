module BaseCoursesHelper

  def humanized_type(base_course)
    case base_course.type
    when 'Course'
      'Course'
    when 'CourseTemplate'
      'Course Template'
    end
  end

end
