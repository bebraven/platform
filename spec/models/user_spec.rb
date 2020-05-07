require 'rails_helper'

RSpec.describe User, type: :model do

  ##############
  # Associations
  ##############

  it { should have_many :program_memberships }
  it { should have_many(:programs).through(:program_memberships) }
  it { should have_many(:roles).through(:program_memberships) }

  #############
  # Validations
  #############

  it { should validate_presence_of :email }
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }

  describe 'validating uniqueness' do
    before { create :registered_user }
    
    it { should validate_uniqueness_of(:email).case_insensitive }
  end
  
  ###########
  # Callbacks
  ###########

  describe '.create' do
    let(:sf_contact) { build(:salesforce_contact) }
    let(:canvas_user) { build(:canvas_user) }
    let(:sf_api_client) { instance_double(SalesforceAPI) }
    let!(:sf_api) { class_double(SalesforceAPI, :client => sf_api_client).as_stubbed_const(:transfer_nested_constants => true) }
    let(:canvas_api_client) { instance_double(CanvasAPI, :find_user_in_canvas => nil, :get_user_enrollments => nil, :get_sections => []) }
    let!(:canvas_api) { class_double(CanvasAPI, :client => canvas_api_client).as_stubbed_const(:transfer_nested_constants => true) }

     context 'when bebraven.org email' do
      it "sets admin true" do
        user = create :user, email: 'test@bebraven.org', password: 'pw123456'
        expect(user.reload.admin).to be(true)
      end
    end

    context "when non-braven email" do
      it "sets admin to false" do
        user = create :user, email: 'bob@example.com', password: 'pw123456'
        expect(user.reload.admin).to be(false)
      end
    end

    context "when salesforce_id is set" do
 
      it 'email and name are fetched from the salesforce_api and set' do
        allow(canvas_api_client).to receive(:find_user_in_canvas).and_return(canvas_user)
        expect(sf_api_client).to receive(:get_contact_info).with(sf_contact['Id']).and_return(sf_contact).once
        user = create :user, password: 'somepassword', salesforce_id: sf_contact['Id']
        user = user.reload
        expect(user.first_name).to eq(sf_contact['FirstName'])
        expect(user.last_name).to eq(sf_contact['LastName'])
        expect(user.email).to eq(sf_contact['Email'])
      end
    end

    context "when salesforce_id is not set" do
      it 'the name and email are left alone' do
        user = create :user, first_name: 'fname', last_name: 'lname', email: 'test@email.com', password: 'somepassword'
        user = user.reload
        expect(user.first_name).to eq('fname')
        expect(user.last_name).to eq('lname')
        expect(user.email).to eq('test@email.com')
        expect(sf_api).not_to receive(:client)
        expect(canvas_api).not_to receive(:client)
      end   
    end

    context 'when canvas user exists' do
      it 'sets the canvas_id' do
        allow(sf_api_client).to receive(:get_contact_info).and_return(sf_contact)
        expect(canvas_api_client).to receive(:find_user_in_canvas).with(sf_contact['Email']).and_return(canvas_user).once
        user = create :user, salesforce_id: sf_contact['Id'], password: 'somepassword'
        user = user.reload
        expect(user.canvas_id).to eq(canvas_user['id'])
      end
    end

    context 'when canvas user doesnt exist' do
      let(:participants) { build_list(:salesforce_participant_fellow, 1, Email: sf_contact['Email']) }
      let(:sf_program) { build(:salesforce_program_record) }
      let(:section) { build(:canvas_section) }
      let(:enrollment) { build(:canvas_enrollment_student) }

      it 'tries to create a canvas user' do
        allow(sf_api_client).to receive(:get_contact_info).and_return(sf_contact)
        allow(sf_api_client).to receive(:get_program_info).and_return(sf_program)
        allow(sf_api_client).to receive(:get_participants).and_return(participants)
        allow(canvas_api_client).to receive(:create_section).and_return(section)
        expect(canvas_api_client).to receive(:create_user).with(anything, anything, anything, sf_contact['Email'], any_args).and_return(canvas_user).once
        expect(canvas_api_client).to receive(:enroll_user_in_course).with(canvas_user['id'], any_args).and_return(enrollment).once
        create :user, salesforce_id: sf_contact['Id'], password: 'somepassword'
      end
    end

  end

  ##################
  # Instance methods
  ##################

  describe 'full_name' do
    let(:user) { build :registered_user }
    
    subject { user.full_name }
    it { should eq("#{user.first_name} #{user.last_name}") }
  end
 
  describe '#start_membership(program_id, role_id)' do
    let!(:user) { create :registered_user }
    let!(:program) { create :program }
    let!(:role) { create :role }
    
    subject { user.start_membership(program.id, role.id) }
    
    describe "when membership doesn't already exist" do
      it { expect(subject.user).to eq(user) }
      it { expect(subject.program).to eq(program) }
      it { expect(subject.role).to eq(role) }
      it { expect(subject.start_date).to eq(Date.today) }
      it { expect(subject.end_date).to eq(nil) }
    end
    
    describe 'when membership aleady exists' do
      let(:start_date) { Date.today - 100 }
      let!(:program_membership) { create :program_membership, user: user, program: program, role: role, start_date: start_date }
      
      it { should eq(program_membership) }
      
      it { expect(subject.user).to eq(user) }
      it { expect(subject.program).to eq(program) }
      it { expect(subject.role).to eq(role) }
      it { expect(subject.start_date).to eq(start_date) }
      it { expect(subject.end_date).to eq(nil) }
    end
  end
  
  describe '#end_membership(program_id, role_id)' do
    let!(:user) { create :registered_user }
    let!(:program) { create :program }
    let!(:role) { create :role }
    let(:start_date) { Date.today - 100 }
    
    subject { user.end_membership(program.id, role.id) }
  
    describe 'when membership exists' do
      let!(:program_membership) { create :program_membership, user: user, program: program, role: role, start_date: start_date }
    
      it { should be_truthy }
      it { subject; expect(program_membership.reload.end_date).to eq(Date.yesterday) }
    end
    
    describe 'when membership does not exist' do
      it { should be_falsey }
    end
  end
  
  describe '#update_membership(program_id, old_role_id, new_role_id)' do
    let!(:user) { create :registered_user }
    let!(:program) { create :program }
    let!(:old_role) { create :role, name: 'Old' }
    let!(:new_role) { create :role, name: 'New' }
    let!(:start_date) { Date.today - 100 }
    
    subject { user.update_membership(program.id, old_role.id, new_role.id) }

    describe 'when membership with old role exists' do
      let!(:program_membership) { create :program_membership, user: user, program: program, role: old_role, start_date: start_date }
    
      it { should be_truthy }
      
      it "ends the program membership with the old role" do
        expect(user).to receive(:end_membership).with(program.id, old_role.id)
        subject
      end
      
      it "creates a program membership with the new role" do
        expect(user).to receive(:start_membership).with(program.id, new_role.id)
        subject
      end
    end
    
    describe 'when membership does not exist' do
      it "attempts to end membership without breaking" do
        expect(user).to receive(:end_membership).with(program.id, old_role.id)
        subject
      end
      
      it "creates a program membership with the new role" do
        expect(user).to receive(:start_membership).with(program.id, new_role.id)
        subject
      end
    end
    
    describe 'when old role and new role are the same' do
      let(:new_role) { old_role }
      let!(:program_membership) { create :program_membership, user: user, program: program, role: old_role, start_date: start_date }
      
      it "does NOT attempt to end membership" do
        expect(user).to_not receive(:end_membership).with(program.id, old_role.id)
        subject
      end
      
      it "does NOT attempt to create a new membership" do
        expect(user).to_not receive(:start_membership).with(program.id, new_role.id)
        subject
      end
    end
  end
  
  describe '#current_membership(program_id)' do
    let!(:user) { create :registered_user }
    let!(:program) { create :program }
    let!(:old_role) { create :role, name: 'Old' }
    let!(:new_role) { create :role, name: 'New' }

    let!(:old_membership) { create :program_membership, user: user, program: program, role: old_role, start_date: Date.today-100, end_date: Date.today-10 }
    let!(:new_membership) { create :program_membership, user: user, program: program, role: new_role, start_date: Date.today-9 }

    subject { user.reload.current_membership(program.id) }
    
    it { should eq(new_membership) }
  end
end
