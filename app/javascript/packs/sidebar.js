// This is the main entrypoint for the Sidebar.
// Things that need to be set up globally for the sidebar go here.
// Run this script by adding <%= javascript_pack_tag 'sidebar' %> to the head of your layout file,
// like app/views/layouts/content_editor.html.erb.


// Dev Only: makes guard-webpacker and hot reloading work.
import WebpackerReact from 'webpacker-react'
import Sidebar from 'components/Sidebar'
WebpackerReact.setup({Sidebar})
