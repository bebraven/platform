class NetworkController < ApplicationController

  def connect
    authorize NetworkPolicy
  end

end
