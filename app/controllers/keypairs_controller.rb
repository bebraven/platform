# https://github.com/Drieam/LtiLauncher
# MIT License
# 
# Copyright (c) 2019 Drieam
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Exposes the public JWKs for currently valid keyparis so that 3rd parties, aka Canvas,
# can decode what we send them.
class KeypairsController < ApplicationController
  skip_before_action :authenticate_user!

  # The Issuer MAY issue a cache-control: max-age HTTP header on
  # requests to retrieve a key set to signal how long the
  # retriever may cache the key set before refreshing it.
  #
  # See: https://www.imsglobal.org/spec/security/v1p0/#h_key-set-url
  def index
    authorize Keypair
    expires_in 1.week, public: true
    render json: { keys: Keypair.valid.map(&:public_jwk_export) }
  end
end
