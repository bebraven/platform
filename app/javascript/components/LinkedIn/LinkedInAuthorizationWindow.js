// Pop-window rendered by linked_in_authorization#launch
//
// We need a new window because LinkedIn won't allow us to embed the 
// authorization flow in an iframe (e.g., how we render Projects in Canvas
// that would display a link to this flow). 
// 
// Note: This component modifies the current browser window. The caller must
// set up a new window if it doesn't want the existing one clobbered.

import Rails from '@rails/ujs';
import React from "react";

class LinkedInAuthorizationWindow extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    // If there's no URL to display, user has gone through the LinkedIn
    // authorization flow and the controller has handled the accept/reject
    // from them.
    if (!this.props.displayUrl) {
      // TODO: https://app.asana.com/0/1174274412967132/1193832365458401
      // Add some sort of confirmation message before we shut down the
      // pop-up. E.g.:
      // setTimeout(function(){window.close()}, 5000);
      // return <someUI />;
      window.close();
      return null;
    }

    // Render LinkedIn's authorization page in pop-up
    window.location = this.props.displayUrl;

    return null; // Rendering handled above, return something by convention
  }
}

export default LinkedInAuthorizationWindow;
