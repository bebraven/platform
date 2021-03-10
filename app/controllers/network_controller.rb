class NetworkController < ApplicationController
  layout 'network'

  def connect
    authorize :network

    @active_requests = []
  end

end
