require 'rails_helper'

RSpec.describe WaiversController, type: :controller do
  render_views

  let(:state) { LtiLaunchController.generate_state }
  let!(:lti_launch) { create(:lti_launch_assignment_selection, target_link_uri: 'https://target/link', state: state) }
  let(:canvas_user_id) { lti_launch.request_message.canvas_user_id }
  let(:canvas_course_id) { lti_launch.request_message.canvas_course_id }
  let!(:user) { create :registered_user, admin: true, canvas_id: canvas_user_id} # TODO: bug where you have to be an admin. Remove admin once that's fixed.
  # TODO: fixme. need to create this with matching course and user. May need to change the factory to pass stuff through or
  # define sub-factories, or create this first and then pass the IDs from here into lti_launch and user factories
  #  let!(:course_membership) { create(:course_membership, base_course_id: canvas_course_id, user_id: user.id) }

# TODO: fixme, record the call to tfaforms in a VCR cassette
#  describe "GET #new" do
#    it "returns a success response" do
#      get :new, params: {state: state}
#      expect(response).to be_successful
#    end
#  end

  describe "POST #create" do

    context "with invalid params" do
      it "redirects to login when state param is missing" do
        post :create, params: {canvas_course_id: '555'}
        expect(response).to redirect_to(new_user_session_path)
      end

      # TODO: tests for canvas user id, canvas_course_id , etc

    end

    context "with valid params" do
      # TODO: fixme one I get the course_membership factory to match stuff up.
      xit "updates the waivers_signed_at date" do
        timestamp = DateTime.now
        allow(DateTime).to receive(:now).and_return(timestamp)
        post :create, params: {state: state, canvas_user_id: canvas_user_id, canvas_course_id: canvas_course_id}
        expect(CourseMembership.where(user_id: user.id, base_course_id: canvas_course_id).first.waivers_signed_at).to eq(timestamp)
      end

      # TODO: implement the rest of the specs
    end
  end
end
