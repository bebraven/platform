import Rails from '@rails/ujs';
import React from "react";

import AttendanceEventSubmissionForm from './AttendanceEventSubmissionForm';

import {
  Button,
  Col,
  Form,
  ToggleButton,
  ToggleButtonGroup,
  Navbar,
} from 'react-bootstrap';

class TakeAttendanceApplication extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      selectedAttendanceEvent: props.courseAttendanceEvents && props.courseAttendanceEvents[0] || null,
      attendanceEventSubmission: props.attendanceEventSubmission,
      isLoaded: props.attendanceEventSubmission || false,
    };
    this._handleAttendanceEventChange = this._handleAttendanceEventChange.bind(this);
    this._fetchAttendanceEventSubmission = this._fetchAttendanceEventSubmission.bind(this);
  }


  componentDidMount() {
    if (!this.props.attendanceEventSubmission && this.state.selectedAttendanceEvent) {
      this._fetchSubmissionAnswers();
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.selectedAttendanceEvent.id != this.state.selectedAttendanceEvent.id) {
      this._fetchAttendanceEventSubmission();
    }
  }

  _handleAttendanceEventChange(event) {
    console.log('_handleAttendanceEventChange');
    console.log(this.state.selectedAttendanceEvent);
    const newAttendanceEvent = this.props.courseAttendanceEvents.find(
      (cae) => cae.id == event.target.value
    );
    console.log(newAttendanceEvent);
    this.setState({
      isLoaded: false,
      selectedAttendanceEvent: newAttendanceEvent,
    });
  }

  _fetchAttendanceEventSubmission() {
    // FIXME: This isn't returning the submission ID given the specified
    // attendance event. WTF.
    //debugger;
    const url = `/attendance_event_submissions/launch.json?course_attendance_event_id=${this.state.selectedAttendanceEvent.id}&state=${this.props.state}`;
    console.log('_fetchAttendanceEventSubmission');
    console.log(url);
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    }).then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            attendanceEventSubmission: result,
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

  _renderAttendanceSubmissionSelector() {
    const course_attendance_events = this.props.courseAttendanceEvents.map(
      (event) => <option value={event.id}>{event.title}</option>
    );
    return (
      <Navbar
        bg="primary"
        className="justify-content-center"
        sticky="top">
      <Form>
        <Form.Row className="align-items-center">
          <h1>Take Attendance For</h1>
        </Form.Row>
        <Form.Row className="align-items-center">
          <Col xs="auto">
            <Form.Group controlId="course_attendance_event">
              <Form.Label>Event</Form.Label>
              <Form.Control as="select" onChange={this._handleAttendanceEventChange}>
                {course_attendance_events}
              </Form.Control>
            </Form.Group>
          </Col>
          <Col xs="auto">
            <Form.Group controlId="course_section">
              <Form.Label>Section</Form.Label>
              <Form.Control as="select">
                <option value={this.props.section.id}>{this.props.section.name}</option>
              </Form.Control>
            </Form.Group>
          </Col>
        </Form.Row>
      </Form>
      </Navbar>
    );
  }

  _renderAttendanceEventSubmissionForm() {
    if (!this.state.selectedAttendanceEvent) {
      return <div><p>Please select an event to take attendance for</p></div>;
    }

    if (!this.state.isLoaded) {
      return <div><p>Loading attendance form...</p></div>;
    }

    if (this.state.error) {
      return <div>{this.state.error}</div>;
    }

    console.log(this.state.attendanceEventSubmission.id);

    return (
      <AttendanceEventSubmissionForm
        submissionId={this.state.attendanceEventSubmission.id}
        eventTitle={this.state.selectedAttendanceEvent.title}
        sectionId={this.props.section.id}
        state={this.props.state}
      />
    );
  }

  render() {
    return (
      <div>
        {this._renderAttendanceSubmissionSelector()}
        {this._renderAttendanceEventSubmissionForm()}
      </div>
    );
  }
}

export default TakeAttendanceApplication;
