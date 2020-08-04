/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Old assets pipeline (Sprockets) stuff that we're moving to Webpacker. These used to 
// be in in: app/assets/javascripts/application.js
require("@rails/ujs").start()
require("turbolinks").start() // Note: this has to be run before any WebpackerReact.setup()
// TODO: if we need to use either of these, start from a fresh Rails 6 install to figure out
// what's missing that causes:  "Module not found: Error"
//require("@rails/activestorage").start()
//require("channels")
import "../stylesheets/application"

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// Uncomment and update the context directory to where you want to load all React components 
// that are applicable to the entire application.
// react-rails
// Support component names relative to this directory:
//
//var componentRequireContext = require.context("app_components", true);
//var ReactRailsUJS = require("react_ujs");
//ReactRailsUJS.useContext(componentRequireContext);
