require 'rails_helper'

RSpec.describe LtiLaunchController, type: :controller do

  let(:valid_session) { { :session_id => SecureRandom.hex(10) } }
  let(:session_id) { valid_session[:session_id] }

  describe 'POST #login' do
    let(:lti_launch_params) { build(:lti_launch_login_params) }

    before(:each) do
      post :login, params: lti_launch_params, session: valid_session
    end

    it 'creates an LtiLaunch' do
      lti_launch = LtiLaunch.current(session_id)
      expect(lti_launch).not_to be_nil
    end 

    it 'sends the LtiLaunch auth_params to the platform redirect_uri' do
      lti_launch = LtiLaunch.current(session_id)
      expect(response).to redirect_to("#{LtiLaunchController::LTI_AUTH_RESPONSE_URL}?#{lti_launch.auth_params.to_query}")
    end 
  end

  describe 'POST #launch' do
    let!(:target_link_uri) { 'https://target/link' }
    let!(:lti_launch) { create(:lti_launch_model, target_link_uri: target_link_uri, state: session_id) }
    let!(:id_token_payload) { FactoryBot.json(:lti_link_launch_request) }
    let!(:id_token) { Keypair.jwt_encode(JSON.parse(id_token_payload, symbolize_names: true)) }
    let!(:lti_launch_params) { { :id_token => id_token, :state => session_id } }

    before(:each) do
      public_jwks = { keys: [ Keypair.current.public_jwk_export ] }.to_json
      stub_request(:get, LtiIdToken::PUBLIC_JWKS_URL).to_return(body: public_jwks)
      post :launch, params: lti_launch_params, session: valid_session
    end

    it 'saves the id_token payload in the LtiLaunch' do
      lti_launch = LtiLaunch.current(session_id)
      expect(JSON.parse(lti_launch.id_token_payload)).to eq(JSON.parse(id_token_payload))
    end 

    it 'redirects to the target_link_uri' do
      expect(response).to redirect_to(target_link_uri)
    end 
  end

end

