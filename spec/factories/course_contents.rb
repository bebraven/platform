FactoryBot.define do
  factory :course_content do
    title { "MyString" }
    body { "MyText" }
    published_at { "2019-11-04 12:45:39" }
    content_type { "MyText" }

    factory :course_content_assignment do
      content_type { "assignment" }
    end

    factory :course_content_module do
      content_type { "wiki_page" }
    end
  end
end
