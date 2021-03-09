# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GradeModuleForUserJob, type: :job do
  describe '#perform' do
    let(:user) { create(:fellow_user) }
    let(:canvas_assignment_id) { '945452' }
    let(:canvas_course_id) { '928374' }
    let(:activity_id) { 'https://some/activity/id' }
    let(:raw_grade) { 75 }
    let(:canvas_client) { double(CanvasAPI) }
    let(:assignment_overrides) { [] }

    before(:each) do
      allow(CanvasAPI).to receive(:client).and_return(canvas_client)
      allow(canvas_client).to receive(:update_grade)
      allow(canvas_client).to receive(:get_assignment_overrides).and_return(assignment_overrides)
      allow(ModuleGradeCalculator).to receive(:compute_grade).and_return(raw_grade)
    end

    subject(:run_job) do
      GradeModuleForUserJob.perform_now(user, canvas_course_id, canvas_assignment_id)
    end

    it 'calls ModuleGradeCalculator with the correct params' do
      run_job
      expect(ModuleGradeCalculator).to have_received(:compute_grade)
        .with(user.id, canvas_assignment_id, assignment_overrides).once
    end

    it 'calls into CanvasAPI to update the grade' do
      run_job
      expect(canvas_client).to have_received(:update_grade)
        .with(canvas_course_id, canvas_assignment_id, user.canvas_user_id, "#{raw_grade}%").once
    end

    it 'sets the module interactions to have status graded' do
      rmi = create(:ungraded_module_interaction, user: user,
        progress: 100, activity_id: activity_id, canvas_course_id: canvas_course_id, canvas_assignment_id: canvas_assignment_id
      )
      another_user = create(:fellow_user, canvas_user_id: 9876543)
      rmi_another_user = create(:ungraded_module_interaction, user: another_user,
        progress: 100, activity_id: activity_id, canvas_course_id: canvas_course_id, canvas_assignment_id: canvas_assignment_id
      )

      run_job

      expect(Rise360ModuleInteraction.where(new: true, user: user,
        canvas_course_id: canvas_course_id, canvas_assignment_id: canvas_assignment_id)
      ).to be_empty
      expect(Rise360ModuleInteraction.where(new: false, user: user,
        canvas_course_id: canvas_course_id, canvas_assignment_id: canvas_assignment_id).count
      ).to be(1)
      expect(Rise360ModuleInteraction.where(new: true, user: another_user,
        canvas_course_id: canvas_course_id, canvas_assignment_id: canvas_assignment_id).count
      ).to be(1)
    end

  end
end
