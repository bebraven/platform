class Champion < ApplicationRecord

  # ensure that industries is empty string if initially NULL/nil
  after_initialize :nils_to_empty_array
  before_save :nils_to_empty_array

  def industries_as_string
    join_with_comma(industries)
  end

  def studies_as_string
    join_with_comma(studies)
  end

  private

  def nils_to_empty_array
    industries ||= []
    studies ||= []
  end

  def join_with_comma(arr)
    arr.join(', ')
  end
  
end
