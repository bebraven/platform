// LinkedIn button rendered by linked_in_authorization#iframe.
// This button launches the LinkedIn authorization flow in a pop-up window.

import Rails from '@rails/ujs';
import React from "react";

import LinkedInButton from 'images/linked_in_button.png';

const WIDTH = 500;
const HEIGHT = 750;

class LinkedInAuthorizationButton extends React.Component {
  constructor(props) {
    super(props);

    this._handleClick = this._handleClick.bind(this);
  }

  _handleClick(event) {
    event.preventDefault();

    // See: https://developer.mozilla.org/en-US/docs/Web/API/Window/open#Window_features
    // Note: setting width and height is the only way to ensure we get a new
    // window (rather than a new tab) on desktop browsers. Mobile browsers
    // open a new window.
    const windowFeatures = {
      width: WIDTH,
      height: HEIGHT, 
      left: (screen.width - WIDTH) / 2,
      top: (screen.height - HEIGHT) / 2,
    };
    const windowFeaturesStr = Object
      .keys(windowFeatures)
      .map((key) => `${key}=${windowFeatures[key]}`)
      .join(',');

    // Open a pop-up window that can be used by LinkedInAuthoriationWindow
    window.open(
      this.props.url,
      '', // this window title gets overwritten by LinkedIn
      windowFeaturesStr,
    );
  }

  render() {
    return (
      <a id="linked-in-login" onClick={this._handleClick}>
        <img src={LinkedInButton} alt="LinkedIn login button" />
      </a>
    );
  }
}

export default LinkedInAuthorizationButton;
