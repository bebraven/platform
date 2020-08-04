# Taken from: https://github.com/waterlink/rack-reverse-proxy/blob/master/spec/support/http_streaming_response_patch.rb
#Copyright (c) 2009 Jon Swope
#
#Permission is hereby granted, free of charge, to any person obtaining
#a copy of this software and associated documentation files (the
#"Software"), to deal in the Software without restriction, including
#without limitation the rights to use, copy, modify, merge, publish,
#distribute, sublicense, and/or sell copies of the Software, and to
#permit persons to whom the Software is furnished to do so, subject to
#the following conditions:
#
#The above copyright notice and this permission notice shall be
#included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

##
# Patch HttpStreamingResponse
# in order to support webmocks and still use rack-proxy
#
# Inspired by @ehlertij commits on sportngin/rack-proxy:
# 616574e452fa731f5427d2ff2aff6823fcf28bde
# d8c377f7485997b229ced23c33cfef87d3fb8693
# 75b446a26ceb519ddc28f38b33309e9a2799074c
# 
module Rack
  class HttpStreamingResponse
    def each(&block)
      response.read_body(&block)
    ensure
      session.end_request_hacked unless mocking?
    end

    protected

    def response
      if mocking?
        @response ||= session.request(@request)
      else
        super
      end
    end

    def mocking?
      defined?(WebMock) || defined?(FakeWeb)
    end
  end
end 
