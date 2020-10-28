# frozen_string_literal: true

class LaunchProgramJob < ApplicationJob
  queue_as :default

  def perform(salesforce_program_id, notification_email, fellow_course_template_id, fellow_course_name, lc_course_template_id, lc_course_name)

    LaunchProgram.new(salesforce_program_id, fellow_course_template_id, fellow_course_name, lc_course_template_id, lc_course_name).run
    LaunchProgramMailer.with(email: notification_email).success_email.deliver_now

  end

  rescue_from(StandardError) do |exception|
    LaunchProgramMailer.with(email: arguments.second, exception: exception).failure_email.deliver_now
  end
end
