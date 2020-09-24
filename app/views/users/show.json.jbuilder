json.user do
  json.full_name @user.full_name
  json.first_name @user.first_name
  json.middle_name @user.middle_name
  json.last_name @user.last_name
  
  json.course_memberships @user.course_memberships do |membership|
    json.course membership.course.name
    json.role membership.role.name
    json.start_date membership.start_date
    json.end_date membership.end_date
    json.current membership.current?
  end
end
