require 'rise360_util'

# A CourseResource is a Rise 360 package that can be associated with one
# or more BaseCourse objects. Once associated with a course in Canvas, it will
# be used in the "Course Navigation" LTI placement as a "Resources" link.
class CourseResource < ApplicationRecord
  has_many :courses
  has_many :course_templates

  after_create_commit :publish

  # Rise 360 resource zipfile
  has_one_attached :course_resource_zipfile

  validates :name, presence: true

  def launch_url
   "#{LtiRise360Proxy.proxy_url}#{Rise360Util.launch_path(course_resource_zipfile.key)}"
  end
   
  private

  def publish
    # TODO: Extract this asynchronously, and ensure update_metadata runs *after*.
    # https://app.asana.com/0/1174274412967132/1184800386160057
    Rise360Util.publish(course_resource_zipfile)
  end
end
