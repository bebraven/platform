require 'rise360_util'

# Represents the contents of a Canvas module, e.g. a Rise 360 course
class LessonContent < ApplicationRecord
  # Note: Callbacks are executed in reverse order.
  after_create_commit :update_metadata!, :publish

  # Rise 360 lesson zipfile
  has_one_attached :lesson_content_zipfile

  def launch_url
   "#{LtiRise360Proxy.proxy_url}#{Rise360Util.launch_path(lesson_content_zipfile.key)}"
  end
   
  private
 
  def publish
    # TODO: Extract this asynchronously, and ensure update_metadata runs *after*.
    # https://app.asana.com/0/1174274412967132/1184800386160057
    Rise360Util.publish(lesson_content_zipfile)
  end

  def update_metadata!
    Rise360Util.update_metadata!(self)
  end

end
