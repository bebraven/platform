// This is the main entrypoint for the Content Editor.
// Things that need to be set up globally go here.
// Run this script by adding <%= javascript_pack_tag 'content_editor' %> to the head of your layout file,
// like app/views/layouts/content_editor.html.erb.

// react-rails - load all components specific to the content_editor layout
// Support component names relative to this directory:
// TODO: rename the "components" directory to "content_editor" so that we can
// create a dir per layout that gets loaded for that layout in the root pack file.
var componentRequireContext = require.context("components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);

// Dev Only: makes guard-webpacker and hot reloading work.
import WebpackerReact from 'webpacker-react'
import ContentEditor from 'components/ContentEditor'
WebpackerReact.setup({ContentEditor})

// Use axe a11y testing in development.
import React from 'react'
import ReactDOM from 'react-dom'
if (process.env.NODE_ENV !== 'production') {
  let axe = require('react-axe');
  document.addEventListener('DOMContentLoaded', () => {
    axe(React, ReactDOM, 1000);
  });
}

