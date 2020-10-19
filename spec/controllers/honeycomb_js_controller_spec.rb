require 'rails_helper'

RSpec.describe HoneycombJsController, type: :controller do
  let(:trace_id) { 'example-trace-id' }
  let(:serialized_trace) { "1;dataset=example-dataset,trace_id=#{trace_id},parent_id=example-parent-id,context=e30=" }

  let(:user) { create :registered_user }
  let!(:lti_launch) { create(:lti_launch_assignment, canvas_user_id: user.canvas_user_id) }

  let(:libhoney_client) { Libhoney::TestClient.new }
  let(:libhoney_event) { double(Libhoney::Event, add_field: nil, send: nil, writekey: 'fakekey') }

  before(:each) do
    # Setup
    request.headers[HoneycombJsController::X_HONEYCOMB_TRACE_HEADER] = serialized_trace
    allow(libhoney_client).to receive(:event).and_return(libhoney_event)
    allow(Honeycomb).to receive(:libhoney).and_return(libhoney_client)

    # Test
    post :send_span, params: beacon, as: :json
  end

  describe 'POST #send_span' do

    context "receives beacon and" do
      let(:duration_ms) { '550' }
      let(:name) { 'some.javascript.event' }
      let(:beacon) { { :state => lti_launch.state, :name => name, :t_done => duration_ms, :field1 => 'value1', :field2 => 'value2'} }

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it "puts it in the correct trace" do
        expect(libhoney_event).to have_received(:add_field).with('trace.trace_id', trace_id).once
      end

      # I couldn't figure out how to do this.
      xit "puts it in the correct parent span" do
        expect(libhoney_event).to have_received(:add_field).with('trace.parent_id', Honeycomb.current_span.id).once
      end

      it "sets the span's name" do
        expect(libhoney_event).to have_received(:add_field).with('name', name).once
      end

      it "sets the duration_ms to t_done field" do
        expect(libhoney_event).to have_received(:add_field).with('duration_ms', duration_ms).once
      end

      it "sets the user.id" do
        expect(libhoney_event).to have_received(:add_field).with('user.id', user.id).once
      end

      it "sets the user.canvas_user_id" do
        expect(libhoney_event).to have_received(:add_field).with('user.canvas_user_id', user.canvas_user_id).once
      end

      it "sets the user.email" do
        expect(libhoney_event).to have_received(:add_field).with('user.email', user.email).once
      end

      it "sets the user.first_name" do
        expect(libhoney_event).to have_received(:add_field).with('user.first_name', user.first_name).once
      end

      it "sets the user.last_name" do
        expect(libhoney_event).to have_received(:add_field).with('user.last_name', user.last_name).once
      end

      it "calls send on Libhoney event" do
        expect(libhoney_event).to have_received(:send).once
      end
    end


    context "receives page unload beacon and" do
      let(:beacon) { JSON.parse(FactoryBot.json(:boomerang_page_unload_beacon, state: lti_launch.state, serialized_trace: serialized_trace)) }

      it "sets the name to 'javascript.page.unload'" do
        expect(libhoney_event).to have_received(:add_field).with('name', 'javascript.page.unload').once
      end

      it "sets the duration_ms to 0" do
        expect(libhoney_event).to have_received(:add_field).with('duration_ms', 0).once
      end
    end


    context "receives page load beacon and" do
      let(:beacon) { JSON.parse(FactoryBot.json(:boomerang_page_load_beacon, state: lti_launch.state, serialized_trace: serialized_trace)) }

      it "sets the name to 'javascript.page.load'" do
        expect(libhoney_event).to have_received(:add_field).with('name', 'javascript.page.load').once
      end

      it "sets the request.path and request.query_string" do
        pathinfo = URI(beacon['u'])
        expect(libhoney_event).to have_received(:add_field).with('request.path', pathinfo.path).once
        expect(libhoney_event).to have_received(:add_field).with('request.query_string', pathinfo.query).once
      end
    end

    context "receives Ajax Fetch beacon and" do
      let(:beacon) { JSON.parse(FactoryBot.json(:boomerang_lrs_query_beacon, state: lti_launch.state, serialized_trace: serialized_trace)) }

      it "sets the request.method" do
        expect(libhoney_event).to have_received(:add_field).with('request.method', 'GET').once
      end

      it "sets the response.status_code" do
        expect(libhoney_event).to have_received(:add_field).with('response.status_code', '200').once
      end
    end

  end

end
