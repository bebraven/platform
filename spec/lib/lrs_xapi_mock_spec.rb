require 'rails_helper'
require 'lrs_xapi_mock'

RSpec.describe LrsXapiMock do

  describe '.handle_request!' do
    let(:request) { ActionDispatch::TestRequest.create }
    let(:user) { create(:fellow_user) }
    let(:url) { "#{Rails.application.secrets.lrs_url}/#{endpoint}" }
    let(:authorization) { "#{LtiConstants::AUTH_HEADER_PREFIX} #{state}" }
    let(:response) { LrsXapiMock.handle_request!(request, endpoint, user) }
    let(:state) { LtiLaunchController.generate_state }
    let!(:lti_launch) { create(:lti_launch_assignment, state: state) }
    let(:response_404) { { body: "Not Found", code: 404 } }
    let(:response_204) { { body: nil, code: 204 } }

    before(:each) do
      allow(request).to receive(:query_parameters).and_return(query_parameters.with_indifferent_access)
      allow(request).to receive(:raw_post).and_return(post_body) if method == 'PUT' || method == 'POST'
      allow(request).to receive(:method).and_return(method)
      allow(request).to receive(:authorization).and_return(authorization)
      allow(GradeModuleForUserJob).to receive(:perform_later).and_return(nil)
      response # This is what makes the request for each test and sets this to the response
    end

    context 'unknown endpoint' do
      let(:endpoint) { 'test_endpoint' }

      context 'GET with no parameters' do
        let(:query_parameters) {{ }}
        let(:method) { 'GET' }

        it 'returns nil' do
          expect(response).to eq(nil)
        end
      end

      context 'PUT with no parameters' do
        let(:query_parameters) {{ }}
        let(:post_body) {{ }.to_json}
        let(:method) { 'PUT' }

        it 'returns 404' do
          expect(response).to eq(response_404)
        end
      end

      context 'POST with no parameters' do
        let(:query_parameters) {{ }}
        let(:post_body) {{ }.to_json}
        let(:method) { 'POST' }

        it 'returns nil' do
          expect(response).to eq(nil)
        end
      end

      context 'DELETE with no parameters' do
        let(:query_parameters) {{ }}
        let(:method) { 'DELETE' }

        it 'returns nil' do
          expect(response).to eq(nil)
        end
      end

    end # context 'any endpoint'

    context 'xAPI statements endpoint' do
      let(:endpoint) { LrsXapiMock::XAPI_STATEMENTS_API_ENDPOINT }

      context 'GET with minimal parameters' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:method) { 'GET' }

        it 'returns nil' do
          expect(response).to eq(nil)
        end
      end

      context 'PUT with minimal parameters' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{ 'testParam': 'test' }.to_json}
        let(:method) { 'PUT' }

        it 'does not save an interaction record' do
          expect(Rise360ModuleInteraction.count).to eq(0)
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end
      end

      context 'PUT with progressed verb' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{
          'actor': 'TEST_REPLACED',
          'verb': { 'id': Rise360ModuleInteraction::PROGRESSED },
          'object': { 'id': 'http://example_activity_id' },
          'result': { 'extensions': {
            'http://w3id.org/xapi/cmi5/result/extensions/progress': 30,
          } },
        }.to_json}
        let(:method) { 'PUT' }

        it 'saves an interaction record' do
          expect(Rise360ModuleInteraction.count).to eq(1)
          expect(Rise360ModuleInteraction.last.verb).to eq(Rise360ModuleInteraction::PROGRESSED)
          expect(Rise360ModuleInteraction.last.progress).to eq(30)
          expect(Rise360ModuleInteraction.last.user).to eq(user)
          expect(Rise360ModuleInteraction.last.activity_id).to eq('http://example_activity_id')
        end

        # We only do this when they finish or nighlty b/c it's computationally and memory intensive.
        it 'does not kick off module grading job' do
          expect(GradeModuleForUserJob).not_to have_received(:perform_later)
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end
      end

      context 'PUT with progressed 100 verb' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{
          'actor': 'TEST_REPLACED',
          'verb': { 'id': Rise360ModuleInteraction::PROGRESSED },
          'object': { 'id': 'http://example_activity_id' },
          'result': { 'extensions': {
            'http://w3id.org/xapi/cmi5/result/extensions/progress': 100,
          } },
        }.to_json}
        let(:method) { 'PUT' }

        it 'saves an interaction record' do
          expect(Rise360ModuleInteraction.count).to eq(1)
          expect(Rise360ModuleInteraction.last.progress).to eq(100)
        end

        it 'kicks off the module grading job' do
          expect(GradeModuleForUserJob).to have_received(:perform_later)
            .with(user,
                  lti_launch.request_message.canvas_course_id,
                  lti_launch.request_message.custom['assignment_id']
            ).once 
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end
      end

      context 'PUT with answered verb' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{
          'actor': 'TEST_REPLACED',
          'verb': { 'id': Rise360ModuleInteraction::ANSWERED },
          'object': { 'id': 'http://example_activity_id' },
          'result': { 'success': true },
        }.to_json}
        let(:method) { 'PUT' }

        it 'saves an interaction record' do
          expect(Rise360ModuleInteraction.count).to eq(1)
          expect(Rise360ModuleInteraction.last.verb).to eq(Rise360ModuleInteraction::ANSWERED)
          expect(Rise360ModuleInteraction.last.success).to eq(true)
          expect(Rise360ModuleInteraction.last.user).to eq(user)
          expect(Rise360ModuleInteraction.last.activity_id).to eq('http://example_activity_id')
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end
      end

      context 'PUT with unsupported verb' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{
          'actor': 'TEST_REPLACED',
          'verb': { 'id': 'http://unsupported_verb' },
          'object': { 'id': 'http://example_activity_id' },
          'result': { 'success': true },
        }.to_json}
        let(:method) { 'PUT' }

        it 'does not save an interaction record' do
          expect(Rise360ModuleInteraction.count).to eq(0)
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end
      end

    end # context 'xAPI statements endpoint'

    context 'xAPI state endpoint' do
      let(:endpoint) { LrsXapiMock::XAPI_STATE_API_ENDPOINT }

      context 'PUT suspend_data' do
        let(:query_parameters) {{
          'stateId': 'suspend_data',
          'activityId': 'test',
        }}
        let(:method) { 'PUT' }
        let(:post_body) { '{"v":1,"d":[123,34]}' }

        it 'creates a state record if it did not exist' do
          expect(Rise360ModuleState.count).to eq(1)
        end

        it 'updates state record value if it already existed, returns 204' do
          expect(Rise360ModuleState.last.value).to eq(post_body)

          post_body = '{"v":1,"d":[123,34,124]}'
          allow(request).to receive(:raw_post).and_return(post_body)
          response = LrsXapiMock.handle_request!(request, endpoint, user)
          expect(response).to eq(response_204)
          expect(Rise360ModuleState.count).to eq(1)
          expect(Rise360ModuleState.last.value).to eq(post_body)
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end

        it 'excepts if validation fails' do
          post_body = 'invalid json'
          allow(request).to receive(:raw_post).and_return(post_body)
          expect {
            LrsXapiMock.handle_request!(request, endpoint, user)
          }.to raise_error
        end
      end

      context 'GET suspend_data' do
        let(:query_parameters) {{
          'stateId': 'suspend_data',
          'activityId': 'test',
        }}
        let(:method) { 'GET' }
        let(:response_body) { '{"v":1,"d":[123,34]}' }

        it 'returns 200 with saved state if it exists' do
          allow(Rise360ModuleState).to receive(:find_by).and_return(Rise360ModuleState.new(value: response_body))
          response = LrsXapiMock.handle_request!(request, endpoint, user)
          expect(response).to eq({code: 200, body: response_body})
        end

        it 'returns 404 if it does not exist' do
          expect(response).to eq(response_404)
        end
      end

      context 'PUT bookmark' do
        let(:query_parameters) {{
          'stateId': 'bookmark',
          'activityId': 'test',
        }}
        let(:method) { 'PUT' }
        let(:post_body) { '#/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy' }

        it 'creates a state record if it did not exist' do
          expect(Rise360ModuleState.count).to eq(1)
        end

        it 'updates state record value if it already existed, returns 204' do
          expect(Rise360ModuleState.last.value).to eq(post_body)

          post_body = '#/lessons/newvalue'
          allow(request).to receive(:raw_post).and_return(post_body)
          response = LrsXapiMock.handle_request!(request, endpoint, user)
          expect(response).to eq(response_204)
          expect(Rise360ModuleState.count).to eq(1)
          expect(Rise360ModuleState.last.value).to eq(post_body)
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end

        it 'excepts if validation fails' do
          post_body = 'long string'*200
          allow(request).to receive(:raw_post).and_return(post_body)
          expect {
            LrsXapiMock.handle_request!(request, endpoint, user)
          }.to raise_error
        end
      end

      context 'GET bookmark' do
        let(:query_parameters) {{
          'stateId': 'bookmark',
          'activityId': 'test',
        }}
        let(:method) { 'GET' }
        let(:response_body) { '#/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy' }

        it 'returns 200 with saved state if it exists' do
          allow(Rise360ModuleState).to receive(:find_by).and_return(Rise360ModuleState.new(value: response_body))
          response = LrsXapiMock.handle_request!(request, endpoint, user)
          expect(response).to eq({code: 200, body: response_body})
        end

        it 'returns 404 if it does not exist' do
          expect(response).to eq(response_404)
        end
      end

      context 'PUT cumulative_time' do
        let(:query_parameters) {{
          'stateId': 'cumulative_time',
          'activityId': 'test',
        }}
        let(:method) { 'PUT' }
        let(:post_body) { '3356598' }

        it 'creates a state record if it did not exist' do
          expect(Rise360ModuleState.count).to eq(1)
        end

        it 'updates state record value if it already existed, returns 204' do
          expect(Rise360ModuleState.last.value).to eq(post_body)

          post_body = '2'
          allow(request).to receive(:raw_post).and_return(post_body)
          response = LrsXapiMock.handle_request!(request, endpoint, user)
          expect(response).to eq(response_204)
          expect(Rise360ModuleState.count).to eq(1)
          expect(Rise360ModuleState.last.value).to eq(post_body)
        end

        it 'returns 204' do
          expect(response).to eq(response_204)
        end

        it 'excepts if validation fails' do
          post_body = 'not an int'
          allow(request).to receive(:raw_post).and_return(post_body)
          expect {
            LrsXapiMock.handle_request!(request, endpoint, user)
          }.to raise_error
        end
      end

      context 'GET cumulative_time' do
        let(:query_parameters) {{
          'stateId': 'cumulative_time',
          'activityId': 'test',
        }}
        let(:method) { 'GET' }
        let(:response_body) { '3356598' }

        it 'returns 200 with saved state if it exists' do
          allow(Rise360ModuleState).to receive(:find_by).and_return(Rise360ModuleState.new(value: response_body))
          response = LrsXapiMock.handle_request!(request, endpoint, user)
          expect(response).to eq({code: 200, body: response_body})
        end

        it 'returns 404 if it does not exist' do
          expect(response).to eq(response_404)
        end
      end

    end # context 'xAPI state endpoint'

  end
end
