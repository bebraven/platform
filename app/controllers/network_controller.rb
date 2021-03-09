class NetworkController < ApplicationController

  def connect
    authorize :network
  end

end
