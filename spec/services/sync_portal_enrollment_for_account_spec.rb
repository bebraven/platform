# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncPortalEnrollmentForAccount do
  describe '#run' do
    let(:portal_user) { CanvasAPI::LMSUser.new }
    let(:sf_participant) { SalesforceAPI::SFParticipant.new('first', 'last', 'test1@example.com') }
    let(:sf_program) { SalesforceAPI::SFProgram.new }
    let(:lms_section) { CanvasAPI::LMSSection.new(10, "test section") }
    let(:lms_enrollment) { CanvasAPI::LMSEnrollment.new(55, 11, RoleConstants::STUDENT_ENROLLMENT, lms_section.id) }
    let(:lms_client) { double('CanvasAPI', find_enrollment: lms_enrollment, find_section_by: lms_section, enroll_user_in_course: nil, create_lms_section: lms_section, delete_enrollment: nil) }
    # Create local models, with the assumption that a user that exists on Canvas must already exist locally too.
    # This all falls apart if that assumption is untrue (the tests will pass, but the code won't work), so be careful
    # if anything changes in this code in the future.
    # Note: This reflects Highlander layout, not the fallback used for Booster/Prod
    # (https://app.asana.com/0/1174274412967132/1197893935338145/f)
    let!(:user) { create(:registered_user, email: sf_participant.email) }
    let!(:course) { create(:course, canvas_course_id: lms_enrollment.course_id) }
    let!(:section) { create(:section, base_course_id: course.id, canvas_section_id: lms_section.id) }

    before(:each) do
      allow(CanvasAPI).to receive(:client).and_return(lms_client)
    end

    context 'for enrolled fellow participant' do
      before(:each) do
        sf_participant.role = SalesforceAPI::FELLOW
        sf_participant.status = SalesforceAPI::ENROLLED
      end

      it 'creates a section if it does not exists' do
        allow(lms_client).to receive(:find_section_by).and_return(nil)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run
        expect(lms_client).to have_received(:create_lms_section)
      end

      it 'creates a default section if no section on salesforce' do
        allow(lms_client).to receive(:find_section_by).and_return(nil)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run
        expect(lms_client)
          .to have_received(:create_lms_section)
          .with(course_id: nil, name: SyncPortalEnrollmentForAccount::DEFAULT_SECTION)
      end

      # Add tests for other sections when implemented

      it 'does not create a section if it exists' do
        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).not_to have_received(:create_lms_section)
      end

      it 'enrolls the user to course if not enrolled' do
        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).to have_received(:enroll_user_in_course).once
      end

      it 'de-enrols a user if section changes' do
        enrollment = CanvasAPI::LMSEnrollment.new(nil, nil, RoleConstants::STUDENT_ENROLLMENT, 2)
        section = CanvasAPI::LMSSection.new(1)
        allow(lms_client).to receive(:find_enrollment).and_return(enrollment)
        allow(lms_client).to receive(:find_section_by).and_return(section)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).to have_received(:delete_enrollment).once
      end

      it 'reenrols the user if section changes' do
        enrollment = CanvasAPI::LMSEnrollment.new(nil, nil, RoleConstants::STUDENT_ENROLLMENT, 2)
        section = CanvasAPI::LMSSection.new(1)
        allow(lms_client).to receive(:find_enrollment).and_return(enrollment)
        allow(lms_client).to receive(:find_section_by).and_return(section)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).to have_received(:enroll_user_in_course).once
      end

      it 'de-enrols a user if role changes' do
        enrollment = CanvasAPI::LMSEnrollment.new(nil, nil, RoleConstants::TA_ENROLLMENT, nil)
        allow(lms_client).to receive(:find_enrollment).and_return(enrollment)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).to have_received(:delete_enrollment).once
      end

      it 'reenrols the user if role changes' do
        enrollment = CanvasAPI::LMSEnrollment.new(nil, nil, RoleConstants::TA_ENROLLMENT, nil)
        allow(lms_client).to receive(:find_enrollment).and_return(enrollment)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).to have_received(:enroll_user_in_course).once
      end
    end

    context 'for dropped fellow participant' do
      before(:each) do
        sf_participant.role = SalesforceAPI::FELLOW
        sf_participant.status = SalesforceAPI::DROPPED
      end

      it 'it drops the user if user is enrolled' do
        allow(lms_client).to receive(:find_enrollment).and_return(lms_enrollment)

        SyncPortalEnrollmentForAccount
          .new(portal_user: portal_user,
               salesforce_participant: sf_participant,
               salesforce_program: sf_program)
          .run

        expect(lms_client).to have_received(:delete_enrollment).once
      end
    end
  end
end
