FactoryBot.define do
  factory :course_resource do
    name { "MyString" }

    factory :course_resource_with_zipfile do
      after :build do |cr, evaluator|
        cr.course_resource_zipfile.attach(io: File.open("#{Rails.root}/spec/fixtures/example_rise360_package.zip"), filename: 'example_rise360_package.zip', content_type: 'application/zip') 
      end
    end
  end
end
