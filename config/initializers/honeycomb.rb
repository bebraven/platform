# frozen_string_literal: true

require 'filter_parameter_logging'

Honeycomb.configure do |config|
  config.write_key = Rails.application.secrets.honeycomb_write_key
  config.dataset = Rails.application.secrets.honeycomb_dataset
  config.presend_hook do |fields|
    FilterHoneycombData.run(fields)
  end
  config.notification_events = %w[
    sql.active_record
    render_template.action_view
    render_partial.action_view
    render_collection.action_view
    process_action.action_controller
    send_file.action_controller
    send_data.action_controller
    deliver.action_mailer
  ].freeze
  # Turn this on if you want to see some craziness
  # config.debug = true
end
