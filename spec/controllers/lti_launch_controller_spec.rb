require 'rails_helper'

RSpec.describe LtiLaunchController, type: :controller do
  let(:state) { SecureRandom.uuid }

  describe 'POST #login' do
    let(:lti_launch_params) { build(:lti_launch_login_params) }

    before(:each) do
      allow(SecureRandom).to receive(:uuid).and_return(state)
      post :login, params: lti_launch_params
    end

    it 'creates an LtiLaunch' do
      lti_launch = LtiLaunch.find_by!(state: state)
      expect(lti_launch).not_to be_nil
    end

    it 'sends the LtiLaunch auth_params to the platform redirect_uri' do
      lti_launch = LtiLaunch.find_by!(state: state)
      expect(response).to redirect_to("#{LtiLaunchController::LTI_AUTH_RESPONSE_URL}?#{lti_launch.auth_params.to_query}")
    end
  end

  describe 'POST #launch' do
    let!(:target_link_uri) { 'https://target/link' }
    let!(:lti_launch) { create(:lti_launch_model, target_link_uri: target_link_uri, state: state) }
    let!(:id_token_payload) { FactoryBot.json(:lti_resource_link_launch_request, target_link_uri: target_link_uri) }
    let!(:id_token) { Keypair.jwt_encode(JSON.parse(id_token_payload, symbolize_names: true)) }
    let!(:lti_launch_params) { { :id_token => id_token, :state => state } }

    context 'user in the launch payload matches a local user by canvas_id' do
      let!(:lti_user) { create(:with_canvas_id_user) }

      before(:each) do
        public_jwks = { keys: [ Keypair.current.public_jwk_export ] }.to_json
        stub_request(:get, LtiIdToken::PUBLIC_JWKS_URL).to_return(body: public_jwks)
        post :launch, params: lti_launch_params
      end

      it 'authenticates the launch' do
        lti_launch = LtiLaunch.current(state)
        expect(lti_launch.id_token_payload).to eq(JSON.parse(id_token_payload))
      end

      it 'redirects to the target_link_uri with the state param' do
        expect(response).to redirect_to(target_link_uri + "?state=#{state}")
      end

      it 'signs in the user with matching canvas_id' do
        expect(controller.current_user).to eq lti_user
      end
    end

    context 'user in the launch payload does not match a local user' do
      before(:each) do
        public_jwks = { keys: [ Keypair.current.public_jwk_export ] }.to_json
        stub_request(:get, LtiIdToken::PUBLIC_JWKS_URL).to_return(body: public_jwks)
        post :launch, params: lti_launch_params
      end

      it 'does not sign in the user' do
        expect(controller.current_user).to eq nil
      end
    end
  end

end

