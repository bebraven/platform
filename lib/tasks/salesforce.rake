namespace :salesforce do

  desc 'Provision Enrolled Participants from Salesforce into Canvas'
  # Example Usage: bundle exec rake salesforce:sync_to_lms[a2Y1J000000YpQFUA0]
  task :sync_to_lms, [:program_id] => :environment do |_, args|
    program_id = args[:program_id]
    puts("### Running Sync To LMS for Program: #{program_id} - #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}")
    require 'sync_portal_enrollments_for_program'
    SyncPortalEnrollmentsForProgram.new(salesforce_program_id: program_id).run
    puts("    Done running Sync To LMS for Program: #{program_id} - #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}")
  end

end
