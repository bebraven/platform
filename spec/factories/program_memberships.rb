FactoryBot.define do
  factory :program_membership do
    user { build(:registered_user) }
    program
    role
  end
end
