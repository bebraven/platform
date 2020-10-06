class CustomContentVersion < ApplicationRecord
  belongs_to :custom_content
  belongs_to :user
end
