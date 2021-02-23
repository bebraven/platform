// This is the main entrypoint for the AttendanceEventSubmissionAnswer.
// Things that need to be set up globally for the sidebar go here.
// Run this script by adding
//  <%= javascript_pack_tag 'attendance_event_submission_answer' %>
// to the head of your layout file, like
//  app/views/layouts/lti_canvas.html.erb.

// Dev Only: makes guard-webpacker and hot reloading work.
import WebpackerReact from 'webpacker-react';
import AttendanceEventSubmissionAnswer from 'components/AttendanceEventSubmissionAnswer';
WebpackerReact.registerComponents({AttendanceEventSubmissionAnswer});
