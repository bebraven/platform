FactoryBot.define do

  # Represents list of Programs returned from
  # SalesforceAPI#get_current_and_future_accelerator_programs()

  factory :salesforce_current_and_future_programs, class: Hash do
    skip_create # This isn't stored in the DB.
    done { true }
    records { [
      build(:salesforce_current_and_future_program_record),
      build(:salesforce_current_and_future_program_record)
    ] }
    totalSize { records.count }
    initialize_with { attributes.stringify_keys }
  end

  factory :salesforce_current_and_future_program_record, class: Hash do
    skip_create # This isn't stored in the DB.
    transient do
      sequence(:program_id) { |i| "a2Y17#{i}00000WLxqEAG" }
    end
    sequence(:Id) { program_id }
    sequence(:Name) { |i| "TEST: Program#{i}" }
    sequence(:Highlander_Accelerator_Course_ID__c)
    # Leaving out 'attributes' key b/c we don't currently use it.
    initialize_with { attributes.stringify_keys }
  end

end

# Example
#{
#  "totalSize": 2,
#  "done": true,
#  "records": [
#    {
#      "attributes": {
#        "type": "Program__c",
#        "url": "/services/data/v49.0/sobjects/Program__c/a2Y15555555555UAY"
#      },
#      "Id": "a2Y15555555555UAY",
#      "Name": "CHI: NLU Summer 2020",
#      "Highlander_Accelerator_Course_ID__c": "555"
#    },
#    {
#      "attributes": {
#        "type": "Program__c",
#        "url": "/services/data/v49.0/sobjects/Program__c/a2Y155555555UAI"
#      },
#      "Id": "a2Y155555555UAI",
#      "Name": "Braven Tech (TEST) Highlander Spring 2021",
#      "Highlander_Accelerator_Course_ID__c": "35555"
#    }
#  ]
#}
