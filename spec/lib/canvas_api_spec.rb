require 'rails_helper'
require 'canvas_api'

RSpec.describe CanvasAPI do

  CANVAS_URL = "http://canvas.example.com".freeze
  CANVAS_API_URL = "#{CANVAS_URL}/api/v1".freeze

  WebMock.disable_net_connect!

  let(:canvas) { CanvasAPI.new(CANVAS_URL, 'test-token') }

  describe '#get' do
    it 'correctly sets authorization header' do
      stub_request(:any, /#{CANVAS_API_URL}.*/)

      canvas.get('/test')

      expect(WebMock).to have_requested(:get, "#{CANVAS_API_URL}/test")
        .with(headers: {'Authorization'=>'Bearer test-token'}).once
    end
  end

  describe '#update_course_page' do
    it 'hits the Canvas API correctly' do
      stub_request(:put, "#{CANVAS_API_URL}/courses/1/pages/test")

      canvas.update_course_page(1, 'test', 'test-body')

      expect(WebMock).to have_requested(:put, "#{CANVAS_API_URL}/courses/1/pages/test").
        with(body: 'wiki_page%5Bbody%5D=%0A++++%3Cdiv+class%3D%22bz-module%22%3E%0A++++%3C%21--+BRAVEN_NEW_HTML+--%3E%0A++test-body%0A++++%3C%2Fdiv%3E%0A++').once
    end
  end

  describe '#create_user' do
    let(:first_name) { 'TestFirstName' }
    let(:last_name) { 'TestLastName' }
    let(:username) { 'testusername' }
    let(:email) { 'test+email@bebraven.org' }
    let(:salesforce_id) { 'a2b17000000ijNRAAY' }
    let(:student_id) { '123456' }
    let(:timezone) { 'America/Los_Angeles' }
    let(:docusign_template_id) { 'abcdedfghijklmnop' }
    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/accounts/1/users"
      stub_request(:post, request_url).to_return( body: FactoryBot.json(:canvas_user) )

      canvas.create_user(first_name, last_name, username, email, salesforce_id, student_id, timezone, docusign_template_id)

      expect(WebMock).to have_requested(:post, request_url)
        .with(body: "user%5Bname%5D=#{first_name}+#{last_name}&user%5Bshort_name%5D=#{first_name}&user%5Bsortable_name%5D=#{last_name}%2C+#{first_name}&user%5Bskip_registration%5D=true&user%5Btime_zone%5D=America%2FLos_Angeles&user%5Bdocusign_template_id%5D=#{docusign_template_id}&pseudonym%5Bunique_id%5D=#{username}&pseudonym%5Bsend_confirmation%5D=false&communication_channel%5Btype%5D=email&communication_channel%5Baddress%5D=test%2Bemail%40bebraven.org&communication_channel%5Bskip_confirmation%5D=true&communication_channel%5Bconfirmation_url%5D=true&pseudonym%5Bsis_user_id%5D=BVSFID#{salesforce_id}-SISID#{student_id}&enable_sis_reactivation=true").once
    end
  end

  describe '#find_user_in_canvas' do
    let(:email) { 'test+email@bebraven.org' }
    let(:course_id) { 71 }
    let(:user_id) { 100 }
    let(:canvas_role) { :StudentEnrollment }
    let(:section_id) { 50 }

    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/accounts/1/users?search_term=#{CGI.escape(email)}&include[]=email"
      response_user = FactoryBot.json(:canvas_user)
      response_json = "[#{response_user}]"
      stub_request(:get, request_url).to_return( body: response_json ) 

      response = canvas.find_user_in_canvas(email)

      expect(WebMock).to have_requested(:get, request_url)
        .with(headers: {'Authorization'=>'Bearer test-token'}).once
      expect(response).to eq(JSON.parse(response_user))
    end

    it 'correctly escapes special characters' do
      request_url = "#{CANVAS_API_URL}/accounts/1/users?include[]=email&search_term=test%2Bterm"
      stub_request(:get, request_url).to_return( body: "[]" ) 

      response = canvas.find_user_in_canvas('test+term')

      expect(WebMock).to have_requested(:get, request_url)
        .with(headers: {'Authorization'=>'Bearer test-token'}).once
    end
  end

  describe '#enroll_user_in_course' do
    let(:course_id) { 71 }
    let(:user_id) { 100 }
    let(:canvas_role) { :StudentEnrollment }
    let(:section_id) { 50 }

    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/courses/#{course_id}/enrollments"
      stub_request(:post, request_url).to_return( body: FactoryBot.json(:canvas_enrollment_student) )

      canvas.enroll_user_in_course(user_id, course_id, canvas_role, section_id)

      expect(WebMock).to have_requested(:post, request_url)
        .with(body: 'enrollment%5Buser_id%5D=100&enrollment%5Btype%5D=StudentEnrollment&enrollment%5Benrollment_state%5D=active&enrollment%5Blimit_privileges_to_course_section%5D=true&enrollment%5Bnotify%5D=false&enrollment%5Bcourse_section_id%5D=50').once   
    end
  end

  describe '#upload_file_to_course' do
    let(:course_id) { 1 }

    it 'POSTS to upload URL' do
      stub_request(:post, "#{CANVAS_API_URL}/courses/#{course_id}/files").
        to_return(body: '{"upload_url":"http://mock.example.com/test", "upload_params":{"test":"param"}}')
      stub_request(:post, "http://mock.example.com/test").
        to_return(body: '{"id":1}')

      upload = canvas.upload_file_to_course(Tempfile.new, 'test.jpg', 'image/jpeg')

      expect(WebMock).to have_requested(:post, "#{CANVAS_API_URL}/courses/#{course_id}/files")
        .with(headers: {'Authorization'=>'Bearer test-token'}).once
      expect(WebMock).to have_requested(:post, "http://mock.example.com/test")
        .once
      expect(upload).to eq({url: "http://canvas.example.com/courses/1/files/1/preview"})
    end
  end

  describe "#update_lesson_grades" do
    let(:course_id) { 111 }
    let(:assignment_id) { 222 }

    it 'POSTS to submissions URL' do
      url = "#{CANVAS_API_URL}/courses/#{course_id}/assignments/#{assignment_id}/submissions/update_grades"

      # Generate random grades for user IDs
      grades_by_user_id = [ 333, 444, 555 ].map{
        |canvas_user_id| [canvas_user_id, rand(1..10)]
      }.to_h

      # Stub request
      stub_request(:post, url).to_return(body: '{}')
      canvas.update_lesson_grades(
        course_id,
        assignment_id,
        grades_by_user_id,
      )

      expect(WebMock)
        .to have_requested(:post, url)
        .once
    end
  end

  describe '#create_course' do
    let(:name) { 'Test Course Name' }
    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/accounts/1/courses"
      stub_request(:post, request_url).to_return( body: FactoryBot.json(:canvas_course) )

      course_data = canvas.create_course(name)

      expect(WebMock).to have_requested(:post, request_url)
        .with(body: "course%5Bname%5D=Test+Course+Name&offer=true").once
      expect(course_data).to have_key('id')
    end
  end

  describe '#content_migration' do
    let(:object_type) { 'courses' }
    let(:object_id) { 42 }
    let(:body) { {
      'migration_type': 'course_copy_importer',
      'settings[source_course_id]': 1,
    } }
    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/#{object_type}/#{object_id}/content_migrations"
      stub_request(:post, request_url).to_return( body: FactoryBot.json(:canvas_content_migration) )

      content_migration = canvas.content_migration(object_type, object_id, body)

      expect(WebMock).to have_requested(:post, request_url)
        .with(body: "migration_type=course_copy_importer&settings%5Bsource_course_id%5D=1").once
      expect(content_migration).to have_key('id')
    end
  end

  describe '#copy_course' do
    let(:source_course_id) { 1 }
    let(:destination_course_id) { 42 }
    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/courses/#{destination_course_id}/content_migrations"
      stub_request(:post, request_url).to_return( body: FactoryBot.json(:canvas_content_migration) )

      content_migration = canvas.copy_course(source_course_id, destination_course_id)

      expect(WebMock).to have_requested(:post, request_url)
        .with(body: "migration_type=course_copy_importer&settings%5Bsource_course_id%5D=#{source_course_id}").once
      expect(content_migration).to have_key('progress_url')
    end
  end

  describe '#get_copy_course_status' do
    let(:progress_url) { "https://braven.instructure.com/api/v1/progress/321" }
    let(:progress_response) { FactoryBot.json(:canvas_content_migration_progress, url: progress_url) }

    it 'hits the Canvas API correctly' do
      stub_request(:get, progress_url).to_return( body: progress_response)

      progress = canvas.get_copy_course_status(progress_url)

      expect(WebMock).to have_requested(:get, progress_url).once
      expect(progress).to have_key('workflow_state')
    end
  end

  describe '#get_assignments' do
    let(:course_id) { 123456 }
    let(:assignment1) { FactoryBot.json(:canvas_assignment, course_id: course_id) }
    let(:assignment2) { FactoryBot.json(:canvas_assignment, course_id: course_id) }

    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/courses/#{course_id}/assignments"
      stub_request(:get, request_url).to_return( body: [assignment1, assignment2].to_json )

      assignments = canvas.get_assignments(course_id)

      expect(WebMock).to have_requested(:get, request_url).once
      expect(assignments.count).to eq(2)
    end
  end

  describe '#create_assignment_overrides' do
    let(:course_id) { 123457 }
    let(:assignemnt_id1) { 1 }
    let(:assignemnt_id2) { 2 }
    let(:section_id1) { 3 }
    let(:section_id2) { 4 }
    let(:override1) { FactoryBot.json(:canvas_assignment_override_section, assignment_id: assignemnt_id1, course_section_id: section_id1) }
    let(:override2) { FactoryBot.json(:canvas_assignment_override_section, assignment_id: assignemnt_id1, course_section_id: section_id2) }
    let(:override3) { FactoryBot.json(:canvas_assignment_override_section, assignment_id: assignemnt_id2, course_section_id: section_id1) }
    let(:override4) { FactoryBot.json(:canvas_assignment_override_section, assignment_id: assignemnt_id2, course_section_id: section_id2) }

    it 'hits the Canvas API correctly' do
      request_url = "#{CANVAS_API_URL}/courses/#{course_id}/assignments/overrides"
      stub_request(:post, request_url).to_return( body: [override1, override2, override3, override4].to_json )

      overrides = canvas.create_assignment_overrides(course_id, [assignemnt_id1, assignemnt_id2], [section_id1, section_id2])

      expect(WebMock).to have_requested(:post, request_url).once
      expect(WebMock).to have_requested(:post, request_url).with(body: "assignment_overrides[][due_at]&assignment_overrides[][assignment_id]=1&assignment_overrides[][course_section_id]=3&assignment_overrides[][due_at]&assignment_overrides[][assignment_id]=1&assignment_overrides[][course_section_id]=4&assignment_overrides[][due_at]&assignment_overrides[][assignment_id]=2&assignment_overrides[][course_section_id]=3&assignment_overrides[][due_at]&assignment_overrides[][assignment_id]=2&assignment_overrides[][course_section_id]=4")

      expect(overrides.count).to eq(4)
    end
  end
end
