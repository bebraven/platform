# frozen_string_literal: true

require 'join_api'

# UpdateJoinUsers finds platform user who are not in join and create them
class UpdateJoinUsers
  def run(entries)
    entries.map do |entry|
      user = entry[:user]
      join_user = find_or_create_join_user!(email: user.email,
                                            first_name: user.first_name,
                                            last_name: user.last_name,
                                            canvas_user_id: entry[:canvas_user_id])
      user.update!(join_user_id: join_user.id)
      join_user
    end
  end

  private

  def find_or_create_join_user!(email:, first_name:, last_name:, canvas_user_id:)
    join_user = join_api_client.find_user_by(email: email)
    return join_user unless join_user.nil?

    join_api_client.create_user(email: email, first_name: first_name,
                                last_name: last_name, canvas_user_id: canvas_user_id)
  end

  def join_api_client
    JoinAPI.client
  end
end
