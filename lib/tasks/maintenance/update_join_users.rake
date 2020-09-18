# frozen_string_literal: true

namespace :maintenance do
  desc 'Run the join user update'
  task update_join_users: :environment do
    users = User.where(join_user_id: nil)
    UpdateJoinUsers.new.run(users)
  end
end
