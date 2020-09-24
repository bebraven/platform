FactoryBot.define do

# Base class to represents an LTI launch request message. The message could either be
# the launch of an already linked "Resource link" or it could be the launch of a
# selection UI in order to create a deep linked resource (or basic resource)
#
# IMPORTANT: this is meant to be built with FactoryBot.json(:lti_link_resource_link)
# and if you don't then it will be missing the json keys that are URLs

  factory :lti_launch_resource_link_request_message, class: Hash do
    skip_create # This isn't stored in the DB.
    iss { 'https://canvas.instructure.com' }
    aud { '160040000000000055' } # Client ID of Developer Key
    azp { '160040000000000055' } # Ditto
    exp { Time.now.to_i + 50000 }
    iat { Time.now.to_i }
    nonce { SecureRandom.hex(10) }
    sub { 'lti_user_id' }        # E.g. "dec802d2-ce78-46ff-9400-847f0a489976
    locale { 'en' }

    # Specifiy these when creating/building to override defaults.
    # E.g. let!(:msg) { FactoryBot.json(:lti_resource_link_message, course_id: 1234) }
    transient do
      message_type { 'LtiResourceLinkRequest' }
      target_link_uri { 'https://platformweb/some/target/uri/to/launch' }
      launch_presentation_return_url { 'https://braven.instructure.com/courses/42/external_content/success/external_tool_redirect' }

      # Values in the Custom variables claim
      account_id { 5 }
      assignment_id { '$Canvas.assignment.id' }
      assignment_title { '$Canvas.assignment.title' }
      assignment_points { '$Canvas.assignment.pointsPossible' }
      attachment_id { '$Canvas.file.media.id' }
      attachment_title { '$Canvas.file.media.title' }
      course_id { 55 }
      course_title { 'ExampleCourseTitle' }
      module_id { '$Canvas.module.id' }
      module_item_id { '$Canvas.moduleItem.id' }
      email { 'example@example.org' }
      first_name { 'MyFirstName' }
      last_name { 'MyLastName' }
      canvas_user_id { 55555 }
      section_ids { '55' } # This is a string, comma delimited if in multiple sections
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
          'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student',
          'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner',
          'http://purl.imsglobal.org/vocab/lis/v2/system/person#User'
        ],
        "https://purl.imsglobal.org/spec/lti-ags/claim/endpoint" => {
          "scope" => [
            "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
            "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly",
            "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
            "https://purl.imsglobal.org/spec/lti-ags/scope/score"
          ],
          "lineitems" => "https://braven.instructure.com/api/lti/courses/42/line_items",
          "validation_context" => nil,
          "errors" => {"errors" => {}}
        },
        "https://purl.imsglobal.org/spec/lti/claim/resource_link" => {
          "id" => "a56fb3404bbf8139dfac9f606c67fb604b0c7474",
          "description" => nil,
          "title" => nil,
          "validation_context" => nil,
          "errors" => {"errors" => {}}
        },
        'https://purl.imsglobal.org/spec/lti/claim/context' => {
          'id' =>'lti_id_of_the_course_context', # E.g. 5fe079b96c274befa5c6f73f5180baab42431578
          'label' => 'CourseLabel',
          'title' => evaluator.course_title,
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
          'return_url' => evaluator.launch_presentation_return_url,
          'locale' => 'en',
        },
        'https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice' => {
          'context_memberships_url' => "https://braven.instructure.com/api/lti/courses/#{evaluator.course_id}/names_and_roles",
          'service_versions' => [ '2.0' ]
        },
        'https://purl.imsglobal.org/spec/lti/claim/custom' => {
          'account_id' => evaluator.account_id,
          'account_name' => 'Course Templates',
          'assignment_id' =>  evaluator.assignment_id,
          'assignment_lti_id' => '$com.instructure.Assignment.lti.id',
          'assignment_points' => evaluator.assignment_points,
          'assignment_title' => evaluator.assignment_title,
          'assignment_due_at' => '$Canvas.assignment.dueAt.iso8601',
          'assignment_lock_date' => '$Canvas.assignment.lockAt.iso8601',
          'assignment_unlock_date' => '$Canvas.assignment.unlockAt.iso8601',
          'attachment_id' => evaluator.attachment_id,
          'attachment_title' => evaluator.attachment_title,
          'browser_info' => 'iframe',
          'context_id' => 'lti_id_of_the_course_context', # E.g. 5fe079b96c274befa5c6f73f5180baab42431578
          'context_source_id' => nil,
          'course_id' => evaluator.course_id,
          'course_name' => evaluator.course_title,
          'course_source_id' => nil,
          'lti_url' => '$LtiLink.custom.url',
          'module_id' => evaluator.module_id, # If not in module, shows up as this in json: "module_id": null
          'module_item_id' => evaluator.module_item_id,
          'role' => 'DesignerEnrollment,Account Admin',
          'section_ids' => evaluator.section_ids,
          'title' => evaluator.course_title,
          'timezone' => 'America/New_York',
          'user_id' => evaluator.canvas_user_id,
          'user_email' => evaluator.email,
          'user_fullname' => "#{evaluator.first_name} #{evaluator.last_name}",
          'user_last_name' => evaluator.last_name,
          'user_first_name' => evaluator.first_name,
          'submission_id' => '$com.instructure.Submission.id',
          'submission_url' => 'api/lti/assignments/{assignment_id}/submissions/{submission_id}',
          'submission_history_url' => 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/history'
        },
        'errors' => { 'errors' => {} }
      })
    end

    initialize_with { attributes.stringify_keys }
  end

end

