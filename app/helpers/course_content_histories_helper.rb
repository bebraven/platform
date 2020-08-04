require 'base64'

module CourseContentHistoriesHelper

  # Turns the HTML for the project into HTML with data-bz-retained
  # elements populated with user inputs, disabled, and highlighted in
  # order to view the project submission.
  def project_submission_html_for(project_lti_id, project_html, student)
    @retrieved_values = fetch_user_data_for(project_lti_id, student)
    doc = Nokogiri::HTML::DocumentFragment.parse(project_html)
    doc.css('[data-bz-retained]').each do |node|
      disable_and_highlight(node)
      if @retrieved_values
        data_input_id = node['data-bz-retained']
        case node.name.downcase
        when 'textarea'
          node.content = get_user_input_for(data_input_id)
        when 'input'
          node['value'] = get_user_input_for(data_input_id)
        end
      end
    end
    doc.to_html
  end

private

  # Returns a hash of data_input_ids => values for all inputs sent to the LRS by this user for this project.
  # Note that the value for a particular ID is the most recent value stored. The user can edit a value
  # multiple times causing there to be many different statement's with various values.
  #
  # Uses the GET statements xApi: https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Communication.md#213-get-statements
  # API.  Each project has a single acitivity_id for it.  
  # See this for more details: app/javascript/packs/xapi_assignment.js
  # TODO: filter by submission. If a project can be re-submitted we need to make sure that we're only
  # showing the submission we're trying to view.
  # Task: https://app.asana.com/0/1174274412967132/1187445581799819
  def fetch_user_data_for(project_lti_id, student)
    # TODO: clean me. up. Use constants. Refactor stuff out in the xAPI parsing classes? Move to JS to be consisten with
    # where we handle xApi stuff: https://app.asana.com/0/1174274412967132/1187336478107377

    # Can't use: Xapi.create_statement_query(...) without modifying the gem b/c it ignores the "ascending" param
    query = Xapi::StatementsQuery.new do |s|
      s.agent = Xapi.create_agent(agent_type: "Agent", email: student.email, name: student.full_name)
      s.verb_id = 'http://adlnet.gov/expapi/verbs/answered'
      s.activity_id = project_lti_id
      #s.registration = TODO: https://app.asana.com/0/1174274412967132/1187332632826993
      s.ascending = true
    end

    response = Xapi.get_statements_by_query(remote_lrs: lrs_api, statement_query: query)
    xapi_statements = JSON.parse(response[:statements].to_json) || {}
    xapi_statements.map { |statement| [ statement['object']['definition']['name']['und'], statement['result']['response'] ] }.to_h
  end

  def disable_and_highlight(node)
    node.append_class('highlighted-user-input')
    node['readonly'] = 'true'
  end

  def get_user_input_for(data_input_id)
    user_data_statement = @retrieved_values[data_input_id] 
    user_data_statement ||= ''
  end

  def lrs_api
    @lrs ||= begin
      # Form the username/password from the auth token. See RFC2617.
      user_name, password = Base64.decode64(Rails.application.secrets.lrs_auth_token).split(':', 2)
      Xapi.create_remote_lrs( end_point: Rails.application.secrets.lrs_url, user_name: user_name, password: password )
    end
  end
end
