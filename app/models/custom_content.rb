require 'canvas_api'

class CustomContent < ApplicationRecord
  has_many :custom_content_versions

  def publish(params)
    response = CanvasAPI.client.update_course_page(params[:course_id], params[:secondary_id], params[:body])

    # Some APIs return 200, some 201.
    response.code == 200 or response.code == 201
  end

  def last_version
    return nil unless custom_content_versions.exists?
    custom_content_versions.last
  end

  def save_version!(user)
    published_at = DateTime.now
    new_version = CustomContentVersion.new({
        custom_content_id: id,
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
