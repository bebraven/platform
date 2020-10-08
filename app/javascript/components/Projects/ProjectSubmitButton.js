import Rails from '@rails/ujs';
import React from "react";

import {
  Alert,
  Form,
  Button,
  Spinner,
} from 'react-bootstrap'

class ProjectSubmitButton extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      alert: null,
      // Note: we *don't* initialize this from props.hasSubmission, see
      // https://reactjs.org/docs/react-component.html#constructor for details.
      // This is a one-way flag. Once you've submitted successfully during 
      // this component's lifecycle, this is never unset. 
      hasSubmission: false,
      isSubmitting: false,
    };

    this._handleSubmit = this._handleSubmit.bind(this);
  }

  _handleSubmit(event) {
    event.preventDefault();

    if (this.state.isSubmitting) {
      return;
    }

    this.setState({isSubmitting: true});

    const form = event.target;
    const data = new FormData(form);

    fetch(
      `/projects/${this.props.projectId}/submissions`,
      {
        method: 'POST',
        body: data,
        headers: {
          'X-CSRF-Token': Rails.csrfToken(),
        },
      },
     )
    .then((response) => {
      this.setState({
        alert: response.ok ? this._successAlert() : this._errorAlert(),
        // If you've successfully submitted this project behavior, getting 
        // an error later doesn't impact that submission. 
        hasSubmission: this.state.hasSubmission || response.ok,
        isSubmitting: false,
      });
    })
    .catch((error) => {
      this.setState({
        isSubmitting: false,
        alert: this._errorAlert(),
      });
    });
  }

  _renderAlert() {
    if (!this.state.alert) {
      return;
    }
    const { heading, body, variant } = this.state.alert;
    return (
      <Alert
        className="fixed-top"
        dismissible
        onClose={() => {this.setState({alert: null})}}
        variant={variant}>
        <Alert.Heading>{heading}</Alert.Heading>
        <p>{body}</p>
      </Alert>
    );
  }

  _successAlert() {
    return {
      heading: 'Success!',
      body: 'Your changes have been saved.',
      variant: 'success',
    };
  }

  _errorAlert() {
    return {
      heading: 'Something went wrong!',
      body: 'Your changes have not been saved. Please try again.',
      variant: 'warning',
    };
  }

  _buttonSpinner() {
    return (
      <span>
        <Spinner
          className="align-middle align-center"
          hidden={!this.state.isSubmitting}
          animation="border"
          role="status"
          size="sm">
          <span className="sr-only">{this._buttonText()}</span>
        </Spinner>
        {' '}
      </span>
    );
  }

  _renderSubmitButton() {
    return (
      <Button
        block
        disabled={this.state.isSubmitting}
        name="project-submit-button"
        size="lg"
        type="submit">
        {this.state.isSubmitting ? this._buttonSpinner() : null }
        {this._buttonText()}
      </Button>);
  }

  _buttonText() {
    if (this.state.isSubmitting) {
      return 'Submitting';
    }

    if (this.props.hasSubmission || this.state.hasSubmission) {
      return 'Re-Submit';
    }

    return 'Submit';
  }

  render() {
    return (
      <div>
        {this._renderAlert()}
        <Form
            inline
            onSubmit={this._handleSubmit}>
            <input
              id="state"
              name="state"
              type="hidden"
              value={this.props.ltiLaunchState}
            />
            {this._renderSubmitButton()}
        </Form>
      </div>
    );
  }
}

export default ProjectSubmitButton;
