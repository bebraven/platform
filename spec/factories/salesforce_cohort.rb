FactoryBot.define do

  # Represents a Cohort returned from the Salesforce API

  factory :salesforce_cohort, class: Hash do
    skip_create # This isn't stored in the DB.
    sequence(:attributes) { |i| 
      "{'type':'Cohort__c', 'url':'/services/data/v48.0/sobjects/Cohort__c/a2V1#{i}000001dcrcEAA'}'"
    }
    sequence(:Name) { |i| "C#{i} Mon SJSU (LCLastName)" }

    initialize_with { attributes.stringify_keys }
  end

end

# Example
# {
#   "attributes":
#   {
#     "type":"Cohort__c", 
#     "url":"/services/data/v48.0/sobjects/Cohort__c/a2V11000001dcrcEAA"
#   }, 
#   "Name":"C1 Mon SJSU (xTestSadler)
# }
