require 'filter_logging'

# TODO: something like the below taken from here:
# https://docs.sentry.io/platforms/ruby/guides/rails/configuration/filtering/#filtering-error-events
#Sentry.init do |config|
#  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
#  config.before_send = lambda do |event, hint|
#    # note1: if you have config.async configured, the event here will be a Hash instead of an Event object
#    # note2: the code below is just an example, you should adjust the logic based on your needs
#    event.request.data = filter.filter(event.request.data)
#    event
#  end
#end
