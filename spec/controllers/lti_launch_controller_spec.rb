require 'rails_helper'

RSpec.describe LtiLaunchController, type: :controller do
  let(:state) { LtiLaunchController.generate_state }

  describe 'POST #login' do
    let(:lti_launch_params) { build(:lti_launch_login_params) }

    before(:each) do
      allow(LtiLaunchController).to receive(:generate_state).and_return(state)
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
    let(:canvas_user_id) { 12345 }
    let!(:target_link_uri) { 'https://target/link' }
    let!(:lti_launch) { create(:lti_launch_canvas, target_link_uri: target_link_uri, state: state, canvas_user_id: canvas_user_id) }
    let!(:id_token_payload) { FactoryBot.json(:lti_launch_assignment_message, target_link_uri: target_link_uri, canvas_user_id: canvas_user_id) }
    let!(:id_token) { Keypair.jwt_encode(JSON.parse(id_token_payload, symbolize_names: true)) }
    let!(:lti_launch_params) { { :id_token => id_token, :state => state } }

    context 'user in the launch payload matches a local user by canvas_user_id' do
      let!(:lti_user) { create(:registered_user, canvas_user_id: canvas_user_id) }

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

      it 'signs in the user with matching canvas_user_id' do
        expect(controller.current_user).to eq lti_user
      end
    end

    context 'user in the launch payload does not match a local user' do
      before(:each) do
        public_jwks = { keys: [ Keypair.current.public_jwk_export ] }.to_json
        stub_request(:get, LtiIdToken::PUBLIC_JWKS_URL).to_return(body: public_jwks)
      end

      it 'does not sign in the user' do
        expect {
          post :launch, params: lti_launch_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

end

