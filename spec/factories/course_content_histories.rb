FactoryBot.define do
  factory :course_content_history do
    title { "MyString" }
    body { "MyText" }

    user { build(:admin_user) }
    course_content
  end
end
