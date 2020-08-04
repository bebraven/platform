FactoryBot.define do

# Represents an LTI Resource link launch request message. E.g. after adding
# a lesson to a Canvas module, when the student goes to open that lesson
# this is the message to launch it.
# See: https://www.imsglobal.org/spec/lti/v1p3#resource-link-launch-request-message
#
# IMPORTANT: this is meant to be built with FactoryBot.json(:lti_link_launch_request)
# and if you don't then it will be missing the json keys that are URLs

  factory :lti_link_launch_request, class: Hash do
    skip_create # This isn't stored in the DB.
    iss { 'https://some.lti.platform' }
    aud { '160040000000000055' }
    azp { '160040000000000055' }
    exp { Time.now.to_i + 50000 }
    iat { Time.now.to_i }
    nonce { SecureRandom.hex(10) }
    sub { 'lti_user_id' }
    locale { 'en' }

    transient do
      target_link_uri { 'https://platformweb/some/target/uri/to/launch' }
      message_type { 'LtiFakeMessageType' }
    end

    factory :lti_resource_link_launch_request, class: Hash do
      transient do
        message_type { 'LtiResourceLinkRequest' }
      end
      before(:json) do |request_msg, evaluator|
        request_msg.merge!({
          'https://purl.imsglobal.org/spec/lti/claim/resource_link' => {
            'id' => 'id_of_the_resource_being_launched',
            'description' => nil,
             'title' => nil
          }
        })
      end
    end

    factory :lti_deep_link_launch_request, class: Hash do
      transient do
        message_type { 'LtiDeepLinkingRequest' }
      end
      before(:json) do |request_msg, evaluator|
        request_msg.merge!({
          'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings' => {
            "accept_types": ["link", "file", "html", "ltiResourceLink", "image"],
            "accept_media_types": "image/:::asterisk:::,text/html",
            "accept_presentation_document_targets": ["iframe", "window", "embed"],
            "accept_multiple": true,
            "auto_create": true,
            "title": "This is the default title",
            "text": "This is the default text",
            "data": "Some random opaque data that MUST be sent back",
            "deep_link_return_url": "https://platformweb/deep_links"
          }
        })
      end
    end

    # These are not valid attributes so they have to be added manually to the hash. Only works when this
    # factory is built using: FactoryBot.json(...) 
    before(:json) do |request_msg, evaluator| 
      request_msg.merge!({
        'https://purl.imsglobal.org/spec/lti/claim/message_type' => evaluator.message_type,
        'https://purl.imsglobal.org/spec/lti/claim/version' => '1.3.0',
        'https://purl.imsglobal.org/spec/lti/claim/deployment_id' => '59:id_of_lti_deployment',
        'https://purl.imsglobal.org/spec/lti/claim/target_link_uri' => evaluator.target_link_uri,
        'https://purl.imsglobal.org/spec/lti/claim/roles' => [
          'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator',
          'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor',
          'http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper',
          'http://purl.imsglobal.org/vocab/lis/v2/system/person#User'
        ],
        'https://purl.imsglobal.org/spec/lti/claim/context' => {
          'id' =>'id_of_the_course_context',
          'label' => 'CourseLabel',
          'title' => 'CourseName',
          'type' => [ 'http://purl.imsglobal.org/vocab/lis/v2/course#CourseOffering' ]
        },
        'https://purl.imsglobal.org/spec/lti/claim/tool_platform' => {
          'guid' => 'id_of_instance_of_platform:canvas-lms',
          'name' => 'Braven - Cloud',
          'version' => 'cloud',
          'product_family_code' => 'canvas'
        },
        'https://purl.imsglobal.org/spec/lti/claim/launch_presentation' => {
          'document_target' => 'iframe',
          'height' => nil,
          'width' => nil,
          'return_url' => 'https://some/path/on/the/platform/to/go/back/to/when/done',
          'locale' => 'en',
        },
# TODO: make the values transiet variabes and set them in the appropriate launch message.
# e.g. a LinkSelection launch won't have an assignment_id. It would be set to "$Canvas.assignment.id"
        'https://purl.imsglobal.org/spec/lti/claim/custom' => {
          'role' => 'DesignerEnrollment,Account Admin',
          'title' =>'CourseTitle',
          'lti_url' => '$LtiLink.custom.url',
          'user_id' => 55555,
          'timezone' => 'America/New_York',
          'course_id' => 55,
          'module_id' => 555,
          'account_id' => 5,
          'context_id' => 'id_of_the_resource_being_launched',
          'user_email' => 'example@exampl.org',
          'course_name' => 'CourseName',
          'section_ids' => '55',
          'account_name' => 'Manually-Created Courses',
          'browser_info' => 'iframe',
          'assignment_id' => '55',
          'attachment_id' => '$Canvas.file.media.id',
          'submission_id' => '$com.instructure.Submission.id',
          'user_fullname' => 'Brian Nairb',
          'module_item_id' => 555,
          'submission_url' => 'api/lti/assignments/{assignment_id}/submissions/{submission_id}',
          'user_last_name' => 'Nairb',
          'user_first_name' => 'Brian',
          'assignment_title' => '$Canvas.assignment.title',
          'attachment_title' => '$Canvas.file.media.title',
          'course_source_id' => nil,
          'assignment_due_at' => '$Canvas.assignment.dueAt.iso8601',
          'assignment_lti_id' => '$com.instructure.Assignment.lti.id',
          'assignment_points' => '$Canvas.assignment.pointsPossible',
          'context_source_id' => nil,
          'assignment_lock_date' => '$Canvas.assignment.lockAt.iso8601',
          'assignment_unlock_date' => '$Canvas.assignment.unlockAt.iso8601',
          'submission_history_url' => 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/history'
        },
        'errors' => { 'errors' => {} },

        # Note: I think these are Canvas specific service URLs available in this launch context. See:
        # https://www.imsglobal.org/spec/lti/v1p3#services-exposed-as-additional-claims
        'https://purl.imsglobal.org/spec/lti-ags/claim/endpoint' => {
          'scope' => [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            'https://purl.imsglobal.org/spec/lti-ags/scope/score'
          ],
          'lineitems' => 'https://platformdomain/api/lti/courses/55/line_items',
          'lineitem' => 'https://platformdomain/api/lti/courses/55/line_items/15'
        },
        'https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice' => {
          'context_memberships_url' => 'https://braven.instructure.com/api/lti/courses/40/names_and_roles',
          'service_versions' => [ '2.0' ]
        }

      })
    end

    initialize_with { attributes.stringify_keys }
  end

end

