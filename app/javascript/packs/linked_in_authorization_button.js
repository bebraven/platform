// This is the main entrypoint for the LinkedInAuthorizationButton.
// Run this script by adding
//  <%= javascript_pack_tag 'linked_in_authorization_button' %>
// to the head of your layout file.

// Dev Only: makes guard-webpacker and hot reloading work.
import WebpackerReact from 'webpacker-react';
import LinkedInAuthorizationButton from 'components/LinkedIn/LinkedInAuthorizationButton';
WebpackerReact.registerComponents({LinkedInAuthorizationButton});
