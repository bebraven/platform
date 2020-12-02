FactoryBot.define do
  factory :grade_category do
    sequence(:name) { |i| "Grade Category Name #{i}" }
    percent_of_grade { 0.25 }

    association :course, factory: :course
  end
end
