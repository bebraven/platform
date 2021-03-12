class Champion < ApplicationRecord

  # ensure that industries is empty string if initially NULL/nil
  after_initialize :nils_to_empty_array
  #before_save :nils_to_empty_array

  private

  def nils_to_empty_array
    industries ||= []
    studies ||= []
  end
  
end
