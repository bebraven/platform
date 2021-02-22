import Rails from '@rails/ujs';
import React from "react";

import {
  Button,
  Col,
  ListGroup,
  Form,
  ToggleButton,
  ToggleButtonGroup,
  Navbar,
  Row,
} from 'react-bootstrap';

class TakeAttendanceApplication extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      isLoaded: false,
      error: null,
      course_attendance_events: [],
      sections: [],
      fellows: [],

      in_attendance: null,
      is_late: false,
      absence_reason: "",
    };

    this._handleChange = this._handleChange.bind(this);
    this._resetInAttendance = this._resetInAttendance.bind(this);
    this._handleLateChange = this._handleLateChange.bind(this);
    this._handleAbsenceReasonChange = this._handleAbsenceReasonChange.bind(this);
  }

  // First called when component mounts, e.g. <react_component ... /> from
  // the ERB file. Do data fetching. This can be optimized away by bootstrapping
  // in data as props to the component.
  componentDidMount() {
    // See: https://reactjs.org/docs/faq-ajax.html

    // 1. Fetch attendance events for this course.
    fetch("/api/courses/3/attendance_events")
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            course_attendance_events: result
          });
        },
        // Note: it's important to handle errors here
        // instead of a catch() block so that we don't swallow
        // exceptions from actual bugs in components.
        (error) => {
          this.setState({
            isLoaded: true,
            error,
          });
        }
      );

    // 2. Fetch sections.
    fetch("/api/courses/3/attendance_sections")
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            sections: result
          });
        },
        // Note: it's important to handle errors here
        // instead of a catch() block so that we don't swallow
        // exceptions from actual bugs in components.
        (error) => {
          this.setState({
            isLoaded: true,
            error,
          });
        }
      );

    fetch("/api/sections/1/users")
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            fellows: result
          });
        },
        // Note: it's important to handle errors here
        // instead of a catch() block so that we don't swallow
        // exceptions from actual bugs in components.
        (error) => {
          this.setState({
            isLoaded: true,
            error,
          });
        }
      );

    // 3. Fetch the submission based on (1) and (2).
  }

  _renderAttendanceSubmissionSelector() {
    const course_attendance_events = this.state.course_attendance_events.map(
      (event) => <option value={event.id}>{event.title}</option>
    );
    const sections = this.state.sections.map(
      (section) => <option value={section.id}>{section.name}</option>
    );
    return (
      <Form>
        <Form.Row className="align-items-center">
          <h1>Take Attendance For</h1>
        </Form.Row>
        <Form.Row className="align-items-center">
          <Col xs="auto">
            <Form.Group controlId="course_attendance_event">
              <Form.Label>Event</Form.Label>
              <Form.Control as="select">
                {course_attendance_events}
              </Form.Control>
            </Form.Group>
          </Col>
          <Col xs="auto">
            <Form.Group controlId="course_section">
              <Form.Label>Section</Form.Label>
              <Form.Control as="select">
                {sections}
              </Form.Control>
            </Form.Group>
          </Col>
          <Col xs="auto">
            <Button variant="primary" type="submit">
              Update
            </Button>
          </Col>
        </Form.Row>
      </Form>
    );
  }

  _renderAttendanceEventSubmissionForm() {
    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm url={submitURL} students={students} />
    // Need the submission URL, the list of students
    return (
      <ListGroup>
        {this.state.fellows.map( (fellow) => <ListGroup.Item>{fellow.name}</ListGroup.Item>)}
      </ListGroup>
    )
  }

  _handleChange(value) {
    console.log('here');
    console.log(value);
    this.setState({
      in_attendance: value,
      is_late: false,
      absence_reason: "",
    });
  }

  _resetInAttendance() {
    this.setState({
      in_attendance: null,
      is_late: false,
      absence_reason: "",
    });
  }

  _renderAttendanceDetails() {
    const absenceReasons = [
      "",
      "Sick / Dr. Appt",
      "Work",
      "School",
      "Caregiving",
      "Bereavement / Family Emergency",
      "Transportation",
      "Professional Development",
      "Vacation",
    ];
    switch(this.state.in_attendance) {
      case true:
        return (
          <Form.Group controlId="isLateCheckbox">
            <Form.Check type="checkbox" label="Late?" value={this.state.is_late} onChange={this._handleLateChange}/>
          </Form.Group>
        );
      case false:
        return (
          <Form.Group controlId="absenceReason">
            <Form.Label>Reason for absence?</Form.Label>
            <Form.Control as="select" value={this.state.absence_reason} onChange={this._handleAbsenceReasonChange} >
              {absenceReasons.map( (reason) => <option>{reason}</option> )}
            </Form.Control>
          </Form.Group>
        );
      default:
        return null;
    }
  }

  _handleAbsenceReasonChange(event) {
    console.log('_handleAbsenceReasonChange');
    console.log(event.target.value);
    this.setState({
      absence_reason: event.target.value,
    });
  }

  _handleLateChange(event) {
    console.log('_handleLateChange');
    console.log(!this.state.is_late);
    this.setState({
      is_late: !this.state.is_late,
    });
  }

  _renderAttendanceReset() {
    if (this.state.in_attendance == null) {
      return null;
    }
    return (
      <Button onClick={this._resetInAttendance}>
        Reset
      </Button>
    );
  }

  _renderAttendanceSubmissionAnswer() {
    return (
      <Row>
        <Col>
        <ToggleButtonGroup type="radio" name="in_attendance" value={this.state.in_attendance} onChange={this._handleChange}>
          <ToggleButton value={true}>Present</ToggleButton>
          <ToggleButton value={false}>Absent</ToggleButton>
        </ToggleButtonGroup>
        </Col>
        <Col>
          {this._renderAttendanceDetails()}
        </Col>
        <Col>
          {this._renderAttendanceReset()}
        </Col>
      </Row>
    );
  }

  render() {
    return (
      <div>
        {this._renderAttendanceSubmissionSelector()}
        {this._renderAttendanceEventSubmissionForm()}
        {this._renderAttendanceSubmissionAnswer()}
      </div>
    );
  }
}

export default TakeAttendanceApplication;
