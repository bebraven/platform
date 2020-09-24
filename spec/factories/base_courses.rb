FactoryBot.define do
  factory :base_course do
    sequence(:name) { |i| "BaseCourse #{i}" }
  end
end
