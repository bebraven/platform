class FormKeyValue < ApplicationRecord
  belongs_to :user

  validates :user, :key, presence: true
end
