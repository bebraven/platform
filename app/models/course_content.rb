require 'canvas_api'

class CourseContent < ApplicationRecord
  has_many :course_content_histories

  def publish(params)
    response = CanvasAPI.client.update_course_page(params[:course_id], params[:secondary_id], params[:body])

    # Some APIs return 200, some 201.
    response.code == 200 or response.code == 201
  end

  def last_version
    return nil unless course_content_histories.exists?
    course_content_histories.last
  end

  def save_version!(user)
    published_at = DateTime.now
    new_version = CourseContentHistory.new({
        course_content_id: id,
        title: title,
        body: body,
        user: user
      })

    transaction do
      new_version.save!
      save!
    end
  end

end
