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
    
    factory :registered_user do
      sequence(:password) { |i| "password#{i}" }
      confirmed_at { DateTime.now }

      factory :fellow_user do
        transient do
          section { build(:section) }
        end
        canvas_user_id { '1234' }
        after :create do |user, options|
          user.add_role RoleConstants::STUDENT_ENROLLMENT, options.section
        end
      end

      factory :ta_user do
        transient do
          section { build(:section) }
        end
        canvas_user_id { '1235' }
        after :create do |user, options|
          user.add_role RoleConstants::TA_ENROLLMENT, options.section
        end
      end

      factory :admin_user do
        after :create do |user|
          user.add_role :admin
        end
      end

      factory :linked_in_user do
        linked_in_state { '' }
      end
    end

  end
end
