require 'rails_helper'
require 'sync_to_lms'

RSpec.describe SyncToLMS do

  describe '#execute' do
    let(:program_info) { build(:salesforce_program_record) }
    let(:fellow_course_id) { program_info['Target_Course_ID_in_LMS__c'].to_i }
    let(:lc_course_id) { program_info['LMS_Coach_Course_Id__c'].to_i }
    let(:section) { build(:canvas_section) }
    let(:user) { build(:canvas_user) }
    let(:users) { build_list(:canvas_user, 2) }
    let(:enrollment) { build(:canvas_enrollment_student) }
    let(:enrollments) { build_list(:canvas_enrollment_student, 2) }
    let(:participants) { build_list(:salesforce_participant_fellow, 2) }

    # Basic mocks that return a default value that is good enough to get
    # SyncToLMS not to throw any exceptions when running. Override how they 
    # respond depending on what each test is targeting.
    let(:sf_api_client) { instance_double(SalesforceAPI, :get_program_info => program_info, :get_participants => []) }
    let!(:sf_api) { class_double(SalesforceAPI, :client => sf_api_client).as_stubbed_const(:transfer_nested_constants => true) }
    let(:canvas_api_client) { 
      instance_double(CanvasAPI, 
        :find_user_in_canvas => nil, :create_user => user, 
        :get_enrollments => [], :enroll_user_in_course => enrollment,
        :get_sections => [], :create_section => section)
    }
    let!(:canvas_api) { class_double(CanvasAPI, :client => canvas_api_client).as_stubbed_const(:transfer_nested_constants => true) }

    subject(:sync) { SyncToLMS.new() } 

    it 'fetches Program info' do
      expect(sf_api_client).to receive(:get_program_info).with(fellow_course_id).and_return(program_info)
      sync.execute(fellow_course_id)
    end

    context 'when there are Participants' do
      let(:sf_api_client) { instance_double(SalesforceAPI, :get_program_info => program_info, :get_participants => participants) }

      it 'fetches Participants' do
        expect(sf_api_client).to receive(:get_participants).with(fellow_course_id).once
        sync.execute(fellow_course_id)
      end

      it 'creates new Canvas users' do
        expect(canvas_api_client).to receive(:create_user).with(anything, anything, anything, participants[0]['Email'], any_args).and_return(users[0]).once
        expect(canvas_api_client).to receive(:create_user).with(anything, anything, anything, participants[1]['Email'], any_args).and_return(users[1]).once
        sync.execute(fellow_course_id)
      end

      it 'skips creating existing Canvas users' do
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[0]['Email']).and_return(users[0])
        expect(canvas_api_client).not_to receive(:create_user).with(anything, anything, anything, participants[0]['Email'], any_args)
        expect(canvas_api_client).to receive(:create_user).with(anything, anything, anything, participants[1]['Email'], any_args).and_return(users[1]).once
        sync.execute(fellow_course_id)
      end

      it 'creates a new Canvas section' do
        section['name'] = participants[0]['CohortName']
        expect(canvas_api_client).to receive(:create_section).with(fellow_course_id, section['name']).and_return(section).once
        sync.execute(fellow_course_id)
      end

      it 'does not create a duplicate Canvas section' do
        section['name'] = participants[0]['CohortName']
        allow(canvas_api_client).to receive(:get_sections).and_return([section])
        expect(canvas_api_client).not_to receive(:create_section).with(anything, section['name'])
        sync.execute(fellow_course_id)
      end

      it 'gets Canvas section list once' do
        expect(canvas_api_client).to receive(:get_sections).once
        sync.execute(fellow_course_id)
      end

      it 'gets Canvas enrollments list once' do
        expect(canvas_api_client).to receive(:get_enrollments).once
        sync.execute(fellow_course_id)
      end

      it 'handles missing timezone' do
        program_info['Default_Timezone__c'] = nil
        expect { sync.execute(fellow_course_id) }.to raise_error(SalesforceAPI::SalesforceDataError)
      end

      it 'handles missing DocuSign template' do
        program_info['Docusign_Template_ID__c'] = nil
        expect(canvas_api_client).to receive(:create_user).with(anything, anything, anything, anything, anything, anything, anything, nil ).twice
        sync.execute(fellow_course_id)
      end

    end

    context 'when they are a Fellow' do
      let(:sf_api_client) { instance_double(SalesforceAPI, :get_program_info => program_info, :get_participants => participants) }

      it 'adds them to the correct section + role' do
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[0]['Email']).and_return(users[0])
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[1]['Email']).and_return(users[1])
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(users[0]['id'], fellow_course_id, :StudentEnrollment, section['id']).once
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(users[1]['id'], fellow_course_id, :StudentEnrollment, section['id']).once
        sync.execute(fellow_course_id)
      end

      let(:old_section) { build(:canvas_section, :name => 'Old Section') }
      let(:new_section) { build(:canvas_section, :name => participants[0]['CohortName']) }

      it 'moves them to a new section' do
        enrollment['course_section_id'] = old_section['id']
        allow(canvas_api_client).to receive(:get_sections).and_return([old_section])
        allow(canvas_api_client).to receive(:get_enrollments).and_return([enrollment])
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[0]['Email']).and_return(enrollment['user']).once
        expect(canvas_api_client).to receive(:create_section).with(fellow_course_id, new_section['name']).and_return(new_section).once
        expect(canvas_api_client).to receive(:cancel_enrollment).with(enrollment).once
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(enrollment['user']['id'], fellow_course_id, :StudentEnrollment, new_section['id']).once
        sync.execute(fellow_course_id)
      end

      it 'skips them if theyre in the right section' do
        enrollment['course_section_id'] = section['id']
        section['name'] = participants[0]['CohortName']
        allow(canvas_api_client).to receive(:get_sections).and_return([section])
        allow(canvas_api_client).to receive(:get_enrollments).and_return([enrollment])
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[0]['Email']).and_return(enrollment['user']).once
        expect(canvas_api_client).not_to receive(:enroll_user_in_course).with(enrollment['user']['id'], any_args)
        sync.execute(fellow_course_id)
      end

#      xit 'handles a missing Student ID' do
#      end
#
#      xit 'sets NLU usernames correctly' do
#        # For NLU, their username isn't their email. It's "#{user_student_id}@nlu.edu" 
#      end
#
#    xit 'handles missing Pre-Accelerator survey Qualtrics id' do
#    end
#
#    xit 'handles missing Post-Accelerator survey Qualtrics id' do
#    end
#
#    xit 'puts users in placeholder sections based on Learning Lab meeting day/times if cohort not set' do
#      # TODO: the logic will be to lookup their LL day/time and map them to generic canvas sections based on that.
#      # See: https://bebraven.slack.com/archives/CLNA91PD3/p1586272915014600
#    end

    end

    context 'when they are a Leadership Coach' do
      let(:participants) { build_list(:salesforce_participant_lc, 2) }
      let(:sf_api_client) { instance_double(SalesforceAPI, :get_program_info => program_info, :get_participants => participants) }

      it 'adds them to correct section Accelerator section + role' do
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[0]['Email']).and_return(users[0])
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[1]['Email']).and_return(users[1])
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(users[0]['id'], fellow_course_id, :TaEnrollment, section['id']).once
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(users[1]['id'], fellow_course_id, :TaEnrollment, section['id']).once
        sync.execute(fellow_course_id)
      end

      it 'adds them to the correct LC Playbook section + role' do
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[0]['Email']).and_return(users[0])
        allow(canvas_api_client).to receive(:find_user_in_canvas).with(participants[1]['Email']).and_return(users[1])
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(users[0]['id'], lc_course_id, :StudentEnrollment, section['id']).once
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(users[1]['id'], lc_course_id, :StudentEnrollment, section['id']).once
        sync.execute(fellow_course_id)
      end

    end

  end

end
