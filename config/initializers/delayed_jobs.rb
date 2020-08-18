Rails.configuration.after_initialize do
  unless Rails.env.test? # These are annoying when running specs. We should test the jobs directly anyway and not as part of app startup

    # Add delayed_jobs that should be run on app startup here:
    CleanupLtiLaunchTableJob.set(wait: 30.seconds).perform_later || Rails.logger.error('Failed to enqueue CleanupLtiLaunchTableJob')

  end
end
