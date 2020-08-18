require 'rails_helper'

RSpec.describe LtiLaunch, type: :model do

  before(:all) do
    REDIRECT_URI = "https://#{Rails.application.secrets.application_host}/lti/launch"
  end

  describe 'database' do
    it { is_expected.to have_db_column(:client_id).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:login_hint).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:lti_message_hint).of_type(:text) }
    it { is_expected.to have_db_column(:target_link_uri).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:nonce).of_type(:string) }
    it { is_expected.to have_db_column(:state).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:id_token_payload).of_type(:text) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_index(:state) }
  end

  describe 'settings' do
    it { expect(described_class::LTI_LAUNCH_REDIRECT_URI).to eq REDIRECT_URI }
  end

  describe 'methods' do

    describe '.authenticate' do
      let!(:unauthenticated_launch) { create(:lti_launch_model) }
      let(:state) { unauthenticated_launch.state }
      let(:payload_target_link_uri) { 'https://some/target/link/uri/inside/payload' }
      let(:id_token_payload) { JSON.parse(FactoryBot.json(:lti_launch_assignment_message, target_link_uri: payload_target_link_uri)) }

      context 'when valid' do

        before(:each) do
          allow(LtiIdToken).to receive(:parse_and_verify).and_return(LtiResourceLinkRequestMessage.new(id_token_payload))
          LtiLaunch.authenticate(state, 'fake_id_token')
        end

        it 'sets id_token_payload' do
          expect(LtiLaunch.current(state).id_token_payload).to eq(id_token_payload) 
        end

        it 'updates target_link_uri' do
          expect(LtiLaunch.current(state).target_link_uri).to eq(payload_target_link_uri) 
        end
      end
    end

    describe '.current' do
      context 'when authenticated' do
        let(:authenticated_launch) { create(:lti_launch_assignment) }
        it 'returns record' do
          expect(LtiLaunch.current(authenticated_launch.state)).to eq(authenticated_launch)
        end
      end

      context 'when unauthenticated' do
        let(:unauthenticated_launch) { create(:lti_launch_model) }
        it 'raises error' do
          expect { LtiLaunch.current(unauthenticated_launch.state) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe '#activity_id' do
      let(:assignment_launch) { create(:lti_launch_assignment, assignment_id: 12345, course_id: 123) }
      let(:assignment_selection_launch) { create(:lti_launch_assignment_selection) }

      it 'returns the correct Canvas assignment URL' do
        expect(assignment_launch.activity_id).to eq("#{Rails.application.secrets.canvas_cloud_url}/courses/123/assignments/12345")
      end

      it 'throws exception on incorrect message type' do
        expect{ assignment_selection_launch.activity_id }.to raise_error(ArgumentError)
      end
    end

    describe '#auth_params' do
      let(:lti_launch) { create(:lti_launch_assignment) }
      let(:auth_params) { lti_launch.auth_params }

      it 'sets the client_id' do
        expect(auth_params[:client_id]).to eq(lti_launch.client_id)
      end 

      it 'sets the redirect_uri' do
        expect(auth_params[:redirect_uri]).to eq(REDIRECT_URI)
      end 

      it 'sets the state' do
        expect(auth_params[:state]).to eq(lti_launch.state)
      end 

      it 'sets the nonce' do
        expect(auth_params[:nonce]).to eq(lti_launch.nonce)
      end 

      it 'sets the login_hint' do
        expect(auth_params[:login_hint]).to eq(lti_launch.login_hint)
      end 

      it 'sets the lti_message_hint' do
        expect(auth_params[:lti_message_hint]).to eq(lti_launch.lti_message_hint)
      end 

    end

  end
end
