FactoryBot.define do

  # Represents a CohortSchedule returned from the Salesforce API

  factory :salesforce_cohort_schedule, class: Hash do
    skip_create # This isn't stored in the DB.
    sequence(:attributes) { |i| 
      "{'type':'CohortSchedule__c', 'url':'/services/data/v48.0/sobjects/CohortSchedule__c/00#{i}170000125IpSAAU'}'"
    }
    sequence(:DayTime__c) { |i| "Monday, #{i}pm" }

    initialize_with { attributes.stringify_keys }
  end

end

# Example
# {
#   "attributes":
#   {
#     "type":"CohortSchedule__c", 
#     "url":"/services/data/v48.0/sobjects/CohortSchedule__c/a3311000001A4eOAAS"
#   }, 
#   "DayTime__c":"Tuesday, 6pm"
# }
