FactoryBot.define do
  factory :user do
    transient do
      names do
        [
          ['Aaron', 'Anderson'], ['Anthony', 'Anderson'], ['Barry', 'Boswick'], ['Bill', 'Boswick'], 
          ['Bob', 'Boswick'], ['Cara', 'Clark'], ['Candice', 'Clark'], ['Carmen', 'Clark'], 
          ['Diana', 'Davis'], ['Daisy', 'Davis'], ['Deirdre', 'Davis'], ['Fred', 'Fox'], 
          ['Fran', 'Fox'], ['Gertie', 'Gray'], ['Greg', 'Gray'], ['Henry', 'Hill'], 
          ['Harrieta', 'Hill'], ['Harvey', 'Hill'], ['Jack', 'Jones'], ['Jenny', 'Jones'], 
          ['John', 'Jones'], ['Jeff', 'Jones']
        ]
      end
    end
    
    sequence(:email) {|i| "test#{i}@example.com"}
    sequence(:first_name) { |i| names[i % names.size][0] }
    sequence(:last_name) { |i| names[i % names.size][1] }
    admin { false }
    
    factory :registered_user do
      sequence(:password) { |i| "password#{i}" }
      confirmed_at { DateTime.now }

      factory :fellow_user do
        canvas_id { '1234' }
      end

      factory :admin_user do
        admin { true }
      end

      factory :linked_in_user do
        linked_in_state { '' }
      end
    end

  end
end
