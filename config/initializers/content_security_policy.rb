# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https
  # TODO: https://app.asana.com/0/1174274412967132/1185543154920201
  # Unsafe-inline styles are bad. Remove this once we've migrated modules to Rise 360.
  policy.style_src   :self, :https, :unsafe_inline
  policy.frame_ancestors :self

  # Customizable through .env
  # Allow plain http, webpack-dev-server, and livereload connections in development.
  policy.connect_src :self, :https, "http://localhost:*", "ws://localhost:*",
                     "http://#{Rails.application.secrets.application_host}:*",
                     "ws://#{Rails.application.secrets.application_host}:*" if Rails.env.development?
  # Allow loading scripts (like livereload.js) from localhost and app host insecurely in development.
  # If you need to loosen the policy only for select controllers, see WaiversController for an example how.
  policy.script_src   :self, :https, "http://localhost:*",
                      "http://#{Rails.application.secrets.application_host}:*",
                      :unsafe_inline if Rails.env.development?
  # Allow sites to iframe our pages.
  policy.frame_ancestors :self, "https://#{Rails.application.secrets.csp_frame_ancestors_host}" if Rails.application.secrets.csp_frame_ancestors_host

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
