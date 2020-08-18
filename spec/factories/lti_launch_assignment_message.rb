FactoryBot.define do

# Represents an LTI Resource Link launch request message for an already Deep Linked
# assignment. E.g. after adding a Project using the Assignment Selection External Tool, 
# when the student goes to open that Project this is the message to launch it.
# See: https://www.imsglobal.org/spec/lti/v1p3#resource-link-launch-request-message
#
# IMPORTANT: this is meant to be built with FactoryBot.json(:lti_launch_assignment_message)
# and if you don't then it will be missing the json keys that are URLs

  factory :lti_launch_assignment_message, parent: :lti_launch_request_message, class: Hash do
    skip_create # This isn't stored in the DB.

    transient do
      message_type { 'LtiResourceLinkRequest' }
      target_link_uri { 'https://platformweb/some/assignment/to/launch' }
      launch_presentation_return_url { "https://braven.instructure.com/courses/#{course_id}/external_content/success/external_tool_redirect" }
      module_id { 555 } # Can be nil if the assignment isn't in a module.
      module_item_id { 444 }
      assignment_id { 123 }
      assignment_title { 'Example Assignment' }
      assignment_points { 10 }
    end

    before(:json) do |request_msg, evaluator|
      request_msg.merge!({
        'https://purl.imsglobal.org/spec/lti/claim/resource_link' => {
          'id' => 'lti_id_of_the_resource_being_launched', # e.g. d3e864a5-d570-403a-94e3-977461972818
          'description' => '',
           'title' => ''
        },
        # See: https://www.imsglobal.org/spec/lti/v1p3#services-exposed-as-additional-claims
        'https://purl.imsglobal.org/spec/lti-ags/claim/endpoint' => {
          'scope' => [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/score'
          ],
          'lineitems' => "https://platformdomain/api/lti/courses/#{evaluator.course_id}/line_items",
          'lineitem' => "https://platformdomain/api/lti/courses/#{evaluator.course_id}/line_items/15"
        }
      })
    end

    initialize_with { attributes.stringify_keys }
  end

end

