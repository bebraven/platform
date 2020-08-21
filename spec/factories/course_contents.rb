FactoryBot.define do
  factory :course_content do
    title { "MyString" }
    body { "MyText" }
    published_at { "2019-11-04 12:45:39" }

    factory :course_content_assignment do
      content_type { "assignment" }
      body {
        "<p>Based on these responses, what are your next steps?</p>"\
        "<textarea id='test-question-id' data-bz-retained=\"h2c2-0600-next-steps\" placeholder=\"\"></textarea>"
      }

      factory :course_content_assignment_with_history do
        course_content_histories { [build(:course_content_history)] }
      end
    end

    factory :course_content_assignment_with_versions do
      content_type { "assignment" }
      body {
        "<p>Latest, saved but not published version content</p>"
      }

      transient do
        versions_count { 1 }
      end

      after(:create) do |course_content, evaluator|
        create_list(
          :project_version,
          evaluator.versions_count,
          course_content: course_content,
        )
      end
    end

    factory :course_content_module do
      content_type { "wiki_page" }
    end
  end
end
