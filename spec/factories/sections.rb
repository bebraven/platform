FactoryBot.define do
  factory :section do
    sequence(:name) { |i| "Section Name #{i}" }
    association :course

    factory :ta_section do
      name { SectionConstants::TA_SECTION }
      association :course
    end

    factory :section_with_canvas_id do
      sequence(:canvas_section_id)
    end
  end
end
