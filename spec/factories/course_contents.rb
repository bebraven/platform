FactoryBot.define do
  factory :course_content do
    title { "MyString" }
    body { "MyText" }
    published_at { "2019-11-04 12:45:39" }
    content_type { "MyText" }

    factory :course_content_assignment do
      content_type { "assignment" }
      body {
        "<p>Based on these responses, what are your next steps?</p>"\
        "<textarea id='test-question-id' data-bz-retained=\"h2c2-0600-next-steps\" placeholder=\"\"></textarea>"
      }
    end

    factory :course_content_module do
      content_type { "wiki_page" }
    end
  end
end
