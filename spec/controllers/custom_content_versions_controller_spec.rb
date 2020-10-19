require 'rails_helper'
require 'lti_score'
require 'lti_advantage_api'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

RSpec.describe CustomContentVersionsController, type: :controller do
  render_views
  let(:custom_content) { create(:custom_content) }
  let(:custom_content_version) { create(:custom_content_version, attributes) }
  let(:attributes) { valid_attributes }
  let(:valid_attributes) { attributes_for(:custom_content_version).merge(custom_content_id: custom_content.id) }
  let(:valid_session) { {} }
  let(:state) { LtiLaunchController.generate_state }

  before do
    sign_in user
    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:get_access_token)
      .and_return('some lti access token')
    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:get_line_item_for_user)
      .and_return({})
  end

  describe 'GET #index' do
    context "admin viewing all versions" do
      let(:user) { create :admin_user }
      
      it 'returns a success response' do
        get :index, params: {custom_content_id: custom_content.id}, session: valid_session
        expect(response).to be_successful
      end
    end

    context "non-admin attempting to view all versions" do
      let(:user) { create :fellow_user }

      it 'raises a not-authorized error' do
        expect {
          get :index, params: {custom_content_id: custom_content.id}, session: valid_session
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create :fellow_user }

    it 'returns a success response' do
      get(
        :show,
        params: {
          custom_content_id: custom_content.id,
          id: custom_content_version.id,
          # Note: we don't pass in state
        },
      )
      expect(response).to be_successful
    end
  end
end