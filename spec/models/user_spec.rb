require 'rails_helper'

RSpec.describe User, type: :model do

  ##############
  # Associations
  ##############

  it { should have_many :course_memberships }
  it { should have_many(:courses).through(:course_memberships) }
  it { should have_many(:roles).through(:course_memberships) }

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
  end

  ##################
  # Instance methods
  ##################

  describe 'full_name' do
    let(:user) { build :registered_user }
    
    subject { user.full_name }
    it { should eq("#{user.first_name} #{user.last_name}") }
  end
 
  describe '#start_membership(course_id, role_id)' do
    let!(:user) { create :registered_user }
    let!(:course) { create :course }
    let!(:role) { create :role }
    
    subject { user.start_membership(course.id, role.id) }
    
    describe "when membership doesn't already exist" do
      it { expect(subject.user).to eq(user) }
      it { expect(subject.course).to eq(course) }
      it { expect(subject.role).to eq(role) }
      it { expect(subject.start_date).to eq(Date.today) }
      it { expect(subject.end_date).to eq(nil) }
    end
    
    describe 'when membership aleady exists' do
      let(:start_date) { Date.today - 100 }
      let!(:course_membership) { create :course_membership, user: user, course: course, role: role, start_date: start_date }
      
      it { should eq(course_membership) }
      
      it { expect(subject.user).to eq(user) }
      it { expect(subject.course).to eq(course) }
      it { expect(subject.role).to eq(role) }
      it { expect(subject.start_date).to eq(start_date) }
      it { expect(subject.end_date).to eq(nil) }
    end
  end
  
  describe '#end_membership(course_id, role_id)' do
    let!(:user) { create :registered_user }
    let!(:course) { create :course }
    let!(:role) { create :role }
    let(:start_date) { Date.today - 100 }
    
    subject { user.end_membership(course.id, role.id) }
  
    describe 'when membership exists' do
      let!(:course_membership) { create :course_membership, user: user, course: course, role: role, start_date: start_date }
    
      it { should be_truthy }
      it { subject; expect(course_membership.reload.end_date).to eq(Date.yesterday) }
    end
    
    describe 'when membership does not exist' do
      it { should be_falsey }
    end
  end
  
  describe '#update_membership(course_id, old_role_id, new_role_id)' do
    let!(:user) { create :registered_user }
    let!(:course) { create :course }
    let!(:old_role) { create :role, name: 'Old' }
    let!(:new_role) { create :role, name: 'New' }
    let!(:start_date) { Date.today - 100 }
    
    subject { user.update_membership(course.id, old_role.id, new_role.id) }

    describe 'when membership with old role exists' do
      let!(:course_membership) { create :course_membership, user: user, course: course, role: old_role, start_date: start_date }
    
      it { should be_truthy }
      
      it "ends the course membership with the old role" do
        expect(user).to receive(:end_membership).with(course.id, old_role.id)
        subject
      end
      
      it "creates a course membership with the new role" do
        expect(user).to receive(:start_membership).with(course.id, new_role.id)
        subject
      end
    end
    
    describe 'when membership does not exist' do
      it "attempts to end membership without breaking" do
        expect(user).to receive(:end_membership).with(course.id, old_role.id)
        subject
      end
      
      it "creates a course membership with the new role" do
        expect(user).to receive(:start_membership).with(course.id, new_role.id)
        subject
      end
    end
    
    describe 'when old role and new role are the same' do
      let(:new_role) { old_role }
      let!(:course_membership) { create :course_membership, user: user, course: course, role: old_role, start_date: start_date }
      
      it "does NOT attempt to end membership" do
        expect(user).to_not receive(:end_membership).with(course.id, old_role.id)
        subject
      end
      
      it "does NOT attempt to create a new membership" do
        expect(user).to_not receive(:start_membership).with(course.id, new_role.id)
        subject
      end
    end
  end
  
  describe '#current_membership(course_id)' do
    let!(:user) { create :registered_user }
    let!(:course) { create :course }
    let!(:old_role) { create :role, name: 'Old' }
    let!(:new_role) { create :role, name: 'New' }

    let!(:old_membership) { create :course_membership, user: user, course: course, role: old_role, start_date: Date.today-100, end_date: Date.today-10 }
    let!(:new_membership) { create :course_membership, user: user, course: course, role: new_role, start_date: Date.today-9 }

    subject { user.reload.current_membership(course.id) }
    
    it { should eq(new_membership) }
  end
end
