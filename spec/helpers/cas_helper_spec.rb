require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the CasHelper. For example:
#
# describe CasHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe CasHelper, type: :helper do

  describe '#safe_service_url' do
    it 'only allows things that match the regex, or are relative' do
      # safe
      expect(safe_service_url('http://braven/')).to eq('http://braven/')
      expect(safe_service_url('https://kits.bebraven.org/test/url')).to eq('https://kits.bebraven.org/test/url')
      expect(safe_service_url('https://portal.bebraven.org')).to eq('https://portal.bebraven.org')
      expect(safe_service_url('https://braven.org')).to eq('https://braven.org')
      expect(safe_service_url('https://braven.instructure.com')).to eq('https://braven.instructure.com')
      expect(safe_service_url('//braven.instructure.com')).to eq('//braven.instructure.com')
      expect(safe_service_url('/my/path')).to eq('/my/path')
      expect(safe_service_url('http://good.braven.org/')).to eq('http://good.braven.org/')
      expect(safe_service_url('http://good.bebraven.org/')).to eq('http://good.bebraven.org/')
      expect(safe_service_url('/')).to eq('/')
      expect(safe_service_url('/good')).to eq('/good')

      # unsafe
      expect(safe_service_url('https://example.com/')).to eq(nil)
      expect(safe_service_url('http://bebraven.example.org/')).to eq(nil)
      expect(safe_service_url('//badwebsite.example.org/')).to eq(nil)
      expect(safe_service_url('//badbraven.org')).to eq(nil)
      expect(safe_service_url('///bad')).to eq(nil)
      expect(safe_service_url('///')).to eq(nil)
      expect(safe_service_url('//')).to eq(nil)
      expect(safe_service_url('http://evilbraven.org/')).to eq(nil)
      expect(safe_service_url('http://evilbebraven.org/')).to eq(nil)
      expect(safe_service_url('http://.bebraven.org/')).to eq(nil)
      expect(safe_service_url('http://.bebraven.org/')).to eq(nil)
      expect(safe_service_url('.example.com')).to eq(nil)
      expect(safe_service_url('.anything/adsijasd/')).to eq(nil)
      expect(safe_service_url('-not.evilwebsite.com')).to eq(nil)
      expect(safe_service_url('anything')).to eq(nil)
      expect(safe_service_url(' spaces ')).to eq(nil)

      # other
      expect(safe_service_url(nil)).to eq(nil)
    end
  end

end
