// This is the main entrypoint for the TakeAttendanceApplication.
// Things that need to be set up globally for the sidebar go here.
// Run this script by adding
//  <%= javascript_pack_tag 'take_attendance_application' %>
// to the head of your layout file, like
//  app/views/layouts/lti_canvas.html.erb.

// Dev Only: makes guard-webpacker and hot reloading work.
import WebpackerReact from 'webpacker-react';
import TakeAttendanceApplication from 'components/TakeAttendanceApplication';
WebpackerReact.registerComponents({TakeAttendanceApplication});
