FactoryBot.define do

  # Represents a Contact returned from the Salesforce API

  factory :salesforce_contact, class: Hash do
    skip_create # This isn't stored in the DB.
    sequence(:Id) { |i| "00#{i}170000125IpSAAU"}
    sequence(:FirstName) { |i| "FirstName#{i}" }
    sequence(:LastName) { |i| "RegionName#{i}" }
    sequence(:Email) { |i| "test#{i}@email.com" }

    initialize_with { attributes.stringify_keys }
  end

end

# Example
#{
#    "Anticipated_Graduation__c": null,
#    "BZ_Geographical_Region__c": null,
#    "BZ_Region__c": "San Francisco Bay Area, San Jose",
#    "Career__c": null,
#    "CreatedDate": "2020-04-20T17:04:21.000+0000",
#    "Current_Employer__c": null,
#    "Current_Major__c": null,
#    "Email": "brian+xtestsyncfellowsjsu3@bebraven.org",
#    "FirstName": "Brian",
#    "Graduate_Year__c": null,
#    "High_School_Graduation_Date__c": null,
#    "Id": "003170000125IpSAAU",
#    "IsEmailBounced": false,
#    "Job_Function__c": null,
#    "LastName": "xTestSyncFellowSJSU3",
#    "Phone": null,
#    "Preferred_First_Name__c": "Brian",
#    "Signup_Date__c": null,
#    "Title": null,
#    "attributes": {
#        "type": "Contact",
#        "url": "/services/data/v48.0/sobjects/Contact/003170000125IpSAAU"
#    }
#}

