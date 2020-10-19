FactoryBot.define do
  factory :custom_content do
    title { "MyString" }
    body { "MyText" }
    published_at { "2019-11-04 12:45:39" }

    factory :custom_content_assignment do
      content_type { "assignment" }
      body {
        "<p>Based on these responses, what are your next steps?</p>"\
        "<textarea id='test-question-id' data-bz-retained=\"h2c2-0600-next-steps\" placeholder=\"\"></textarea>"
      }

      factory :custom_content_assignment_with_version do
        custom_content_versions { [build(:custom_content_version)] }
      end
    end

    factory :custom_content_assignment_with_versions do
      content_type { "assignment" }
      body {
        "<p>Latest, saved but not published version content</p>"
      }

      transient do
        versions_count { 1 }
      end

      after(:create) do |custom_content, evaluator|
        create_list(
          :project_version,
          evaluator.versions_count,
          custom_content: custom_content,
        )
      end
    end

    factory :custom_content_module do
      content_type { "wiki_page" }
    end
  end
end
