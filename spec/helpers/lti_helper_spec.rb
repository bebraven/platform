require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the LtiHelper. For example:
#
# describe LtiHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe LtiHelper, type: :helper do
  let(:state) { SecureRandom.uuid }
  let(:target_link_uri) { 'https://target/link' }
  let(:lti_launch) { create(:lti_launch_deep_link, target_link_uri: target_link_uri, state: state) }
  let(:content_items_url) { 'https://deep/link' }
  let(:expected_payload) { create(:lti_launch_deep_link).id_token_payload }

  describe "lti_deep_link_response_message" do
    it "returns the deep link url and a payload with an iframe" do
      # Replace Keypair.jwt_encode with a block that just passes the argument through as the return value.
      allow(Keypair).to receive(:jwt_encode) { |x| x }

      deep_link_url, unencoded_payload = helper.lti_deep_link_response_message(lti_launch, content_items_url)
      # This /deep_links url comes from the factory.
      expect(deep_link_url).to eq "https://platformweb/deep_links"
      expect(unencoded_payload["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiDeepLinkingResponse"
      expect(unencoded_payload["https://purl.imsglobal.org/spec/lti-dl/claim/content_items"][0]["url"]).to eq content_items_url
    end
  end
end
