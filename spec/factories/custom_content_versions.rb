FactoryBot.define do
  factory :custom_content_version do
    title { "MyString" }
    body { "MyText" }

    user { build(:admin_user) }
    custom_content

    factory :project_version do
      body {
        "<p>Based on these responses, what are your next steps?</p>"\
        "<textarea id='test-question-id' data-bz-retained=\"h2c2-0600-next-steps\" placeholder=\"\"></textarea>"
      }
    end
  end
end
