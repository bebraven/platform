require 'rest-client'

class CanvasAPI
  UserNotOnCanvas = Class.new(StandardError)

  LMSUser = Struct.new(:id, :email)
  LMSEnrollment = Struct.new(:id, :course_id, :type, :section_id)
  LMSSection = Struct.new(:id, :name)

  TA_ENROLLMENT = :TaEnrollment
  STUDENT_ENROLLMENT = :StudentEnrollment

  attr_reader :canvas_url

  # Custom HTML to prepend to each body.
  # Note: We add a "new HTML" comment here to flag this page as coming from the
  # new content editor. This is referenced in several places in Canvas code.
  # We also wrap the entire contents in a "bz-module" div, so the CSS selectors
  # work as expected.
  PrependHTML = %q(
    <div class="bz-module">
    <!-- BRAVEN_NEW_HTML -->
  )

  # Custom HTML to append to each body.
  AppendHTML = %q(
    </div>
  )

  # Canvas course ID for the Braven Content Library.
  ContentLibraryCourseID = 1

  # Use this to get an instance of the API client with authentication info setup.
  def self.client
    @client_instance ||= new(ENV['CANVAS_URL'], ENV['CANVAS_TOKEN'])
  end

  def initialize(canvas_url, canvas_token)
    @canvas_url = canvas_url
    @api_url = "#{@canvas_url}/api/v1"
    @global_headers = {
      'Authorization' => "Bearer #{canvas_token}",
    }
  end

  def get(path, params={}, headers={})
    RestClient.get("#{@api_url}#{path}", {params: params}.merge(@global_headers.merge(headers)))
  end

  def post(path, body, headers={})
    RestClient.post("#{@api_url}#{path}", body, @global_headers.merge(headers))
  end

  def put(path, body, headers={})
    RestClient.put("#{@api_url}#{path}", body, @global_headers.merge(headers))
  end

  def delete(path, body={}, headers={})
    # Delete helper method doesn't accept a payload. Have to drop down lower level.
    RestClient::Request.execute(method: :delete, 
      url: "#{@api_url}#{path}", payload: body, headers: @global_headers.merge(headers))
  end

  def update_course_page(course_id, wiki_page_id, wiki_page_body)
    body = {
      'wiki_page[body]' => PrependHTML + wiki_page_body + AppendHTML,
    }

    put("/courses/#{course_id}/pages/#{wiki_page_id}", body)
  end

  # Batch updates grades for lessons using the Canvas Submissions API:
  # https://canvas.instructure.com/doc/api/submissions.html#method.submissions_api.update
  # grades_by_user_id: hash containing canvas_user_id => grade
  def update_lesson_grades(course_id, assignment_id, grades_by_user_id)
    body = grades_by_user_id.map { |canvas_user_id, grade|
      [ "grade_data[#{canvas_user_id}][posted_grade]", grade.to_s]
    }.to_h

    response = post(
      "/courses/#{course_id}/assignments/#{assignment_id}/submissions/update_grades",
      body,
    )

    JSON.parse(response.body)
  end

  def create_account(first_name:, last_name:, user_name:, email:, contact_id:, student_id:, timezone:, docusign_template_id:)
    user = create_user(first_name, last_name, user_name, email, contact_id, student_id, timezone, docusign_template_id)

    LMSUser.new(user['id'])
  end

  def create_user(first_name, last_name, username, email, salesforce_id, student_id, timezone, docusign_template_id=nil)
    body = {
        'user[name]' => "#{first_name} #{last_name}",
        'user[short_name]' => first_name,
        'user[sortable_name]' => "#{last_name}, #{first_name}",
        'user[skip_registration]' => true,
        'user[time_zone]' => timezone,
        'user[docusign_template_id]' => docusign_template_id,
        'pseudonym[unique_id]' => username,
        'pseudonym[send_confirmation]' => false,
        'communication_channel[type]' => 'email',
        'communication_channel[address]' => email,
        'communication_channel[skip_confirmation]' => true,
        'communication_channel[confirmation_url]' => true,
         # Note: the old code used the Join user.id and not the SF id. But now the user account may not
         # be created yet when we're running Sync To LMS.
        'pseudonym[sis_user_id]' => format_to_sis_id(salesforce_id, student_id),
        'enable_sis_reactivation' => true
    }
    response = post('/accounts/1/users', body)
    JSON.parse(response.body)
  end

  def find_user_by!(email:)
    user = find_user_in_canvas(email)
    raise UserNotOnCanvas, "Email: #{email}" if user.nil?

    LMSUser.new(user['id'], user['email'])
  end

  def find_user_by(email:, salesforce_contact_id:, student_id:)
    user = find_user_in_canvas(email)
    if user.nil?
      user = find_user_in_canvas(
        format_to_sis_id(salesforce_contact_id, student_id)
      )
    end

    return nil if user.nil?

    LMSUser.new(user['id'], user['email'])
  end


  def find_user_in_canvas(search_term)
    response = get("/accounts/1/users?search_term=#{CGI.escape(search_term)}")
    users = JSON.parse(response.body)
    users.length == 1 ? users[0] : nil
  end 

  # Returns an array of enrollments objects for the course.
  # See: https://canvas.instructure.com/doc/api/enrollments.html
  # Example Usage:
  #   get_course_enrollments(71, [:StudentEnrollment, :TaEnrollment])
  def get_enrollments(course_id, types=[])
    query_params = "per_page=100"
    types.each { |t| query_params += "&type[]=#{t}"}
    response = get("/courses/#{course_id}/enrollments?#{query_params}")
    get_all_from_pagination(response)
  end

  # Same as get_enrollments() but just for a single user
  def get_user_enrollments(user_id, course_id=nil, types=[])
    query_params = "per_page=100"
    types.each { |t| query_params += "&type[]=#{t}"}
    response = get("/users/#{user_id}/enrollments")
    # TODO: if course_id is sent, filter the response to only include those for that course
    enrollments = get_all_from_pagination(response)
    (enrollments.blank? ? nil : enrollments) # No enrollments returns an empty array and nil is nicer to deal with.
  end

  def find_enrollment(user_id:, course_id:)
    enrollment = get_user_enrollments(user_id, course_id)
      &.filter { |e| e['course_id']&.to_i.eql?(course_id&.to_i) }
      &.last
    return enrollment if enrollment.nil?

    LMSEnrollment.new(enrollment['id'], enrollment['course_id'],
                      enrollment['type'].to_sym, enrollment['course_section_id'])
  end

  # Enrolls the user in the new course, without modifying any existing data
  def enroll_user_in_course(canvas_user_id, course_id, canvas_role, section_id)
    body = {
      'enrollment[user_id]' => canvas_user_id,
      'enrollment[type]' => canvas_role,
      'enrollment[enrollment_state]' => 'active',
      'enrollment[limit_privileges_to_course_section]' => true,
      'enrollment[notify]' => false,
      'enrollment[course_section_id]' => section_id
    }
    post("/courses/#{course_id}/enrollments", body)
  end

  def delete_enrollment(enrollment:)
    cancel_enrollment(
      { 'course_id' => enrollment.course_id, 'id' => enrollment.id }
    )
    nil
  end

  # See: https://canvas.instructure.com/doc/api/enrollments.html#method.enrollments_api.destroy
  # Valid values for task:
  #   conclude, delete,  deactivate
  #
  # Note: when deleting their enrollment and then re-enrolling them, it doesn't appear to lose
  # any data (like magic fields or submissions)
  def cancel_enrollment(enrollment, task='delete')
    response = delete("/courses/#{enrollment['course_id']}/enrollments/#{enrollment['id']}", {'task' => task})
    JSON.parse(response.body)
  end

  def find_section_by(course_id:, name:)
    sections = get_sections(course_id)
    section = sections.filter { |s| s['name'] == name }&.first
    return nil if section.nil?

    LMSSection.new(section['id'], section['name'])
  end

  def get_section(section_id)
    response = get("/sections/#{section_id}")
    JSON.parse(response.body)
  end

  def get_sections(course_id)
    response = get("/courses/#{course_id}/sections?per_page=100")
    get_all_from_pagination(response)
  end

  def create_lms_section(course_id:, name:)
    section = create_section(course_id, name)
    # Check what create section returns
    LMSSection.new(section['id'], section['name'])
  end

  def create_section(course_id, section_name)
    response = post("/courses/#{course_id}/sections", {'course_section[name]' => section_name})
    JSON.parse(response.body)
  end

  # See: https://canvas.instructure.com/doc/api/file.pagination.html
  def get_all_from_pagination(response)
    info = JSON.parse(response.body)
    while response
      link = response.headers[:link]
      break if link.nil?

      # Find the line in the link header that looks like the following and pull the URL out:
      # <https://bebraven.instructure.com/api/v1/courses/:id/assignements>; rel="next"
      match = link.match(/.*<(?<url>.+)>; rel="next"/)
      next_url = (match ? match[:url] : nil)
      if next_url
        # Turn something like this: https://portal.bebraven.org/api/v1/courses/71/enrollments?page=2&per_page=100
        # into this: /courses/71/enrollments?page=2&per_page=100
        # So that we can use the get() convenience method in case we ever add centralized logic / error handling there.
        next_url.sub!(/^.*api\/v1/, '')
        response = get(next_url)
        more_info = JSON.parse(response.body)
        info.concat(more_info)
      else
        response = nil
      end
    end

    info
  end

  # See: https://canvascoach.instructure.com/doc/api/file.file_uploads.html#method.file_uploads.post
  # If successful, URL will be available as the hash value of the 'url' key.
  # If unsuccessful, returns a Response object.
  def upload_file_to_course(file, original_filename, content_type, course_id=ContentLibraryCourseID)
    # Step 1: Telling Canvas about the file upload and getting a token.
    body = {
      name: original_filename,
      size: file.size,
      content_type: content_type,
    }

    response = post("/courses/#{course_id}/files", body)
    return response if response.code != 200

    info = JSON.parse(response.body)

    # Step 2: Upload the file data to the URL given in the previous response.
    response = RestClient.post(info['upload_url'], info['upload_params'].merge(file:file))
    return response if ![200, 301].include? response.code

    # Return preview URL.
    info = JSON.parse(response.body)
    {url: "#{canvas_url}/courses/#{course_id}/files/#{info['id']}/preview"}

  end

  private

  def format_to_sis_id(salesforce_contact_id, student_id)
    "BVSFID#{salesforce_contact_id}-SISID#{student_id}"
  end
end
