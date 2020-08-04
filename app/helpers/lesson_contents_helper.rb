# frozen_string_literal: true

require 'lrs_xapi_proxy'

# Helps configure xApi enabled content to be able to send xApi statements to
# a Learners Record Store (LRS).
# 
# Note: The endpoint for the LRS is set to a the LRS_PATH on this server and 
# requests are proxied through to the actual LRS using LrsXapiProxy
#
# See:
# - https://articulate.com/support/article/Implementing-Tin-Can-API-to-Support-Articulate-Content#launching-public-content
# - https://xapi.com/try-developer/
# - https://learningpool.com/how-to-launch-elearning-content-using-xapi/
module LessonContentsHelper
  
  USERNAME_PLACEHOLDER = "LESSON_CONTENTS_USERNAME_REPLACE"
  PASSWORD_PLACEHOLDER = "LESSON_CONTENTS_PASSWORD_REPLACE"

# TODO: we can also provide an activity_id and registration. These are ways to group xApi statements together.
# I'm thinking each lesson or project has an activity_id to group the statements for that and then we have a 
# registration for the course to get all statements for a user for a particular course (in case they take multiple or drop and try again).
# However, will we need a finer grained level to group statements than just project / lesson?
  def launch_query
    lrs_proxy_url = URI(root_url)
    lrs_proxy_url.path = LrsXapiProxy.lrs_path
    {
      :endpoint => lrs_proxy_url.to_s,
      # Our LRS proxy will supply the correct values for these
      # Send empty values to get the Rise 360 Tincan code won't error out on missing keys
      :actor => '{"name":"'"#{USERNAME_PLACEHOLDER}"'", "mbox":["mailto:'"#{PASSWORD_PLACEHOLDER}"'"]}',
      # Note: has to be a UUID. I tried putting the URL of the course and that failed with an error saying it's gotta be UUID.
      # But with this, we get this in the XAPI statement:
      #   "registrations": [
      #     "760e3480-ba55-4991-94b0-01820dbd23a2"
      #   ]
      # TODO: We need to create a registration UUID for each course and set it appropriately for the current
      # course that the LTI launch is happening in. Or maybe just use the value of the "context" in the LTI launch. It's the
      # same concept. An LTI context ID is just the course. Also see if the value of registration can just be an integer or URI,
      # then we could use the canvas course ID or URL and not have to store it
      # Task: https://app.asana.com/0/1174274412967132/1187332632826993
      # :registration => '760e3480-ba55-4991-94b0-01820dbd23a2' 

      # Note: in case you try to set the activity_id through the launch params, it doesn't work. Rise359 packages
      # set it to whatever was specified when you exported the package. We should use their IDs but we need to coordinate
      # with designers on what to do here b/c we have the potential to be inconsistent making the data hard to gather.
      # Actually, this means a single export that is imported into different courses needs the registration set so we can
      # pull data for that lesson just for the current course and not just any course.
      # ALSO, we *could* set the activity id either when we publish it or on the fly by changing the
      # TC_COURSE_ID variable in tc-config.js
      # ALSO note that the "experienced" statement send the activity ID appended with another ID to identify the section
      # of the lesson. The IDs are defined in tincan.xml. See here for an example:
      # https://platform-dev-file-uploads.s3.amazonaws.com/lessons/ytec17h3ckbr92vcf7nklxmat4tc/tincan.xml
      #      :activity_id => url_encode('https://braven.instructure.com/courses/48/assignments/158')

    }
  end
end
