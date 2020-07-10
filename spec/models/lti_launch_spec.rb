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
    it { is_expected.to have_db_column(:nonce).of_type(:string).with_options(null: false) }
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
    subject(:lti_launch) { create(:lti_launch_resource) }
    let(:state_param) { lti_launch.state }

    describe '.current' do
      context 'when exists' do
        it 'is found' do
          session_id = state_param
          expect(LtiLaunch.current(session_id)).to eq(lti_launch) 
        end
      end
    end

    describe '#auth_params' do
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
