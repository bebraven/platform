require 'lesson_content_publisher'

# Represents the contents of a Canvas module, e.g. a Rise 360 course
class LessonContent < ApplicationRecord
  after_create_commit :publish

  # Rise 360 lesson zipfile
  has_one_attached :lesson_content_zipfile

  def launch_url
   "#{LtiLessonContentsProxy.proxy_url}#{LessonContentPublisher.launch_path(lesson_content_zipfile.key)}"
  end
   
  private
 
  def publish
    # TODO: Extract this asynchronously
    # https://app.asana.com/0/1174274412967132/1184800386160057
    LessonContentPublisher.publish(lesson_content_zipfile)
  end

end
