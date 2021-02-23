import Rails from '@rails/ujs';
import React from "react";

import AttendanceEventSubmissionAnswer from './AttendanceEventSubmissionAnswer';

import {
  Alert,
  Button,
  Spinner,
  Navbar,
} from 'react-bootstrap';

class AttendanceEventSubmissionForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isLoaded: false,
      isSubmitting: false,
      alert: null,
      attendanceEventSubmissionAnswers: null,
    };

    this._handleSubmit = this._handleSubmit.bind(this);
    this._onInAttendanceChange = this._onInAttendanceChange.bind(this);
    this._onLateChange = this._onLateChange.bind(this);
    this._onAbsenceReasonChange = this._onAbsenceReasonChange.bind(this);
    this._onClear = this._onClear.bind(this);
  }

  componentDidMount() {
    this._fetchAttendanceEventSubmissionAnswers();
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.submissionId != prevProps.submissionId) {
      this._fetchAttendanceEventSubmissionAnswers();
    }
  }

  _fetchAttendanceEventSubmissionAnswers() {
    this.setState({
      isLoaded: false,
    });

    const url = `/attendance_event_submissions/${this.props.submissionId}/answers.json?state=${this.props.state}&section_id=${this.props.sectionId}`;
    fetch(url)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            attendanceEventSubmissionAnswers: result,
          });
        },
        (error) => {
          this.setState({
            isLoaded: true,
            error,
          });
        }
      );
  }

  _onInAttendanceChange(value, event) {
    this._updateAttendanceEventSubmissionAnswer(
      parseInt(event.target.name),
      {
        in_attendance: value,
        late: false,
        absence_reason: "",
      },
    );
  }

  _onLateChange(event) {
    const idx = parseInt(event.target.name);
    const prevVal = this.state.attendanceEventSubmissionAnswers[idx].late == null
      ? false
      : this.state.attendanceEventSubmissionAnswers[idx].late;
    this._updateAttendanceEventSubmissionAnswer(
      parseInt(event.target.name),
      {
        in_attendance: true,
        late: !prevVal,
        absence_reason: "",
      }
    );
  }

  _onAbsenceReasonChange(event) {
    this._updateAttendanceEventSubmissionAnswer(
      parseInt(event.target.name),
      {
        absence_reason: event.target.value,
        in_attendance: false,
        late: false,
      },
    );
  }

  _onClear(event) {
    this._updateAttendanceEventSubmissionAnswer(
      parseInt(event.target.name),
      {
        in_attendance: null,
        late: false,
        absence_reason: "",
      },
    );
  }

  _updateAttendanceEventSubmissionAnswer(idx, answer) {
    this.state.attendanceEventSubmissionAnswers[idx].in_attendance = answer.in_attendance;
    this.state.attendanceEventSubmissionAnswers[idx].late = answer.late;
    this.state.attendanceEventSubmissionAnswers[idx].absence_reason = answer.absence_reason;
    this.setState({
      attendanceEventSubmissionAnswers: this.state.attendanceEventSubmissionAnswers,
    });
  }

  _handleSubmit(event) {
    event.preventDefault();

    if (this.state.isSubmitting) {
      return;
    }

    this.setState({
      isSubmitting: true,
    });

    let data = {};
    this.state.attendanceEventSubmissionAnswers.map(
      (answer) => data[answer.for_user_id] = {
        in_attendance: answer.in_attendance,
        late: answer.late,
        absence_reason: answer.absence_reason,
      },
    );
    data = {
      attendance_event_submission: data,
    };

    fetch(
      `/attendance_event_submissions/${this.props.submissionId}.json?state=${this.props.state}&section_id=${this.props.sectionId}`,
      {
        method: 'PUT',
        body: JSON.stringify(data),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
        },
      },
     )
    .then((response) => {
      this.setState({
        isSubmitting: false,
        alert: response.ok ? this._successAlert() : this._errorAlert(),
      });
    })
    .catch((error) => {
      this.setState({
        isSubmitting: false,
        alert: this._errorAlert(),
      });
    });
      // .then(res => res.json())
      // .then(
      //   (result) => {
      //     this.setState({
      //       isSubmitting: false,
      //     });
      //   },
      //   (error) => {
      //     this.setState({
      //       isSubmitting: false,
      //       error,
      //     });
      //   }
      // );
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

  _renderSaveButton() {
    return (
      <Button
        onClick={this._handleSubmit}
        disabled={this.state.isSubmitting}
        type="submit">
        {this.state.isSubmitting ? this._buttonSpinner() : null }
        {this._buttonText()}
      </Button>
    );
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

  _buttonText() {
    return this.state.isSubmitting ? 'Saving' : 'Save';
  }

  render() {
    if (!this.state.isLoaded) {
      return <div><p>Loading...</p></div>;
    }

    return (
      <div>
        <h1>Attendance for {this.props.eventTitle}</h1>
        <div>
          {this.state.attendanceEventSubmissionAnswers.map(
            (answer, index) => <AttendanceEventSubmissionAnswer
              key={answer.for_user_id}
              name={index.toString()}
              answer={answer}
              onInAttendanceChange={this._onInAttendanceChange}
              onLateChange={this._onLateChange}
              onAbsenceReasonChange={this._onAbsenceReasonChange}
              onClear={this._onClear}
            />
          )}
        </div>
        <div>
          {this._renderAlert()}
        </div>
        <Navbar
          bg="transparent"
          className="justify-content-end"
          fixed="bottom">
          {this._renderSaveButton()}
        </Navbar>
      </div>
    );
  }
}

export default AttendanceEventSubmissionForm;
