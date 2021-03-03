class UserRole < ApplicationRecord
  # This model is meant only for careful use when you need
  # optimized queries beyond what Rolify generally offers!
  # See https://github.com/RolifyCommunity/rolify/issues/318
  # for more information.
  self.table_name = 'users_roles'

  belongs_to :user
  belongs_to :role
end
