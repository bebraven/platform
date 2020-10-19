require 'rails_helper'

RSpec.describe User, type: :model do

  ##############
  # Associations
  ##############

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

  end

  ##################
  # Instance methods
  ##################

  describe 'full_name' do
    let(:user) { build :registered_user }
    
    subject { user.full_name }
    it { should eq("#{user.first_name} #{user.last_name}") }
  end
end
