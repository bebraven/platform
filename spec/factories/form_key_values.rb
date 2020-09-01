FactoryBot.define do
  factory :form_key_value do
    user { build(:registered_user) }
    key { "MyKey" }
    value { "MyValue" }
  end
end
