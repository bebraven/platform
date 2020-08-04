require 'rails_helper'

RSpec.describe LessonContentsHelper, type: :helper do

  before(:all) do
    ENV['LRS_URL'] = 'https://example.lrs.com/data/xAPI'
    ENV['LRS_AUTH_TOKEN'] = 'IFDJ_EXAMPLE_TOKENoasdfj'
  end

  describe '#to_query' do
    let(:lrs_proxy_url) { 
      uri = URI(root_url)
      uri.path = '/data/xAPI'
      uri
    }

    it 'creates the endpoint parameter' do
      query = helper.launch_query
      endpoint = query[:endpoint]
      expect(query).to have_key(:endpoint)
      expect(query[:endpoint]).to eq(lrs_proxy_url.to_s)
    end

    it 'creates the actor parameter' do
      query = helper.launch_query
      expect(query).to have_key(:actor)
    end
  end
end
