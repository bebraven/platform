class NetworkController < ApplicationController
  layout 'network'
  before_action :authorize_network
  skip_before_action :authenticate_user!, only: [:join, :create_champion]
  
  def connect
    @active_requests = []
  end

  def join
    @industries = list_names_in_table(Industry)
    @studies = list_names_in_table(Field)
    @areas = [
      "Newark, NJ",
      "New York City, NY",
      "San Francisco Bay Area, San Jose",
      "Chicago",
      "National"
    ]
  end

  def create_champion
    c = Champion.create!(params['champion'].permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :company,
      :job_title,
      :linkedin_url,
      :braven_fellow,
      :braven_lc,
      :region,
      :willing_to_be_contacted
    ))
    c.industries = params[:industries]
    c.studies = params[:studies]
    c.save!
  end

  private

  def authorize_network
    authorize :network
  end

  def list_names_in_table(model)
    model.all.order(:name).pluck(:name)
  end
end
