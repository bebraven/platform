FactoryBot.define do

# Represents an LTI Deep Linking request message to select an Assignment and
# create a deep linked resource with it. E.g. when adding an assignment in Canvas,
# when you choose "External Tool" as the submission type, this is the message sent
# in the LTI launch.
#
# IMPORTANT: this is meant to be built with FactoryBot.json(:lti_launch_assignment_selection_message)
# and if you don't then it will be missing the json keys that are URLs

  factory :lti_launch_assignment_selection_message, parent: :lti_launch_request_message, class: Hash do
    skip_create # This isn't stored in the DB.

    transient do
      message_type { 'LtiDeepLinkingRequest' }
      target_link_uri { 'https://platformweb/lti/assignment_selection/uri' }
      launch_presentation_return_url { "https://braven.instructure.com/courses/#{course_id}/external_content/success/external_tool_dialog" }
      deep_link_return_url { "https://braven.instructure.com/courses/#{course_id}/deep_linking_response?modal=true" } 
    end

    before(:json) do |request_msg, evaluator|
      request_msg.merge!({
        'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings' => {
          "accept_media_types": "application/vnd.ims.lti.v1.ltilink",
          "accept_multiple": false,
          "accept_presentation_document_targets": [ "iframe", "window" ],
          "accept_types": [ "ltiResourceLink" ],
          "auto_create": false,
          "deep_link_return_url": evaluator.deep_link_return_url
        }
      })
    end

    initialize_with { attributes.stringify_keys }
  end

end

