# This file will create dummy data for the application, if not already present.
# This SHOULD NOT be used in production, which is why it's separate from the
# seeds file.

# Add the admin users
User.find_or_create_by email: 'admin@beyondz.org' do |u|
  u.first_name = 'Dev'
  u.last_name = 'Admin(BZ)'
  u.password = "#{ENV['DEV_ENV_USER_PASSWORD']}"
  u.confirmed_at = DateTime.now
  u.admin = true
end
User.find_or_create_by email: 'admin@bebraven.org' do |u|
  u.first_name = 'Dev'
  u.last_name = 'Admin(BV)'
  u.password = "#{ENV['DEV_ENV_USER_PASSWORD']}"
  u.confirmed_at = DateTime.now
  u.admin = true
end
User.find_or_create_by email: 'booster.admin@bebraven.org' do |u|
 u.first_name = 'Dev'
 u.last_name = 'Admin(Booster)'
 u.password = "#{ENV['DEV_ENV_USER_PASSWORD']}"
 u.confirmed_at = DateTime.now
 u.admin = true
end

user_count = User.count
FactoryBot.create_list(:registered_user, 5) unless user_count > 3
puts "Created #{User.count - user_count} users"

course = Course.find_or_create_by! name: 'SJSU'
role = Role.find_or_create_by! name: 'Participant'

User.all.each{|p| p.start_membership(course.id, role.id) if p.program_memberships.empty?}

######
# TODO: this is just quick and dirty for testing the grading related models I'm working on. Clean it up
####


grade_category1 = GradeCategory.find_or_create_by! name: 'Category 1', base_course: course, percent_of_grade: 0.75
grade_category2 = GradeCategory.find_or_create_by! name: 'Category 2', base_course: course, percent_of_grade: 0.25

project1 = Project.find_or_create_by! name: 'Test Project 1', grade_category: grade_category1, percent_of_grade_category: 0.5, points_possible: 10
project2 = Project.find_or_create_by! name: 'Test Project 2', grade_category: grade_category2, percent_of_grade_category: 0.5, points_possible: 20, grades_published_at: DateTime.now 

ProjectSubmission.find_or_create_by! user: User.first, project: project1, points_received: 10, submitted_at: DateTime.now
ProjectSubmission.find_or_create_by! user: User.first, project: project2, points_received: 20, submitted_at: DateTime.now
ProjectSubmission.find_or_create_by! user: User.second, project: project1, points_received: 5, submitted_at: DateTime.now
ProjectSubmission.find_or_create_by! user: User.second, project: project2, points_received: 10, submitted_at: DateTime.now

lesson1 = Lesson.find_or_create_by! name: 'Test Lesson 1', grade_category: grade_category1, percent_of_grade_category: 0.5, points_possible: 50
lesson2 = Lesson.find_or_create_by! name: 'Test Lesson 2', grade_category: grade_category2, percent_of_grade_category: 0.5, points_possible: 100

LessonSubmission.find_or_create_by! user: User.first, lesson: lesson1, points_received: 50, submitted_at: DateTime.now
LessonSubmission.find_or_create_by! user: User.first, lesson: lesson2, points_received: 100, submitted_at: DateTime.now
LessonSubmission.find_or_create_by! user: User.second, lesson: lesson1, points_received: 25, submitted_at: DateTime.now
LessonSubmission.find_or_create_by! user: User.second, lesson: lesson2, points_received: 50, submitted_at: DateTime.now

