FactoryBot.define do
  factory :custom_content do
    title { "MyString" }
    body { "MyText" }
    published_at { "2019-11-04 12:45:39" }

    factory :project, class: 'Project' do
      type { "Project" }
      body {
        "<p>Based on these responses, what are your next steps?</p>"\
        "<textarea id='test-question-id' data-bz-retained=\"h2c2-0600-next-steps\" placeholder=\"\"></textarea>"
      }
    end
  end
end
