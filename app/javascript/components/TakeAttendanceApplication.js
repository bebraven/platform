import Rails from '@rails/ujs';
import React from "react";

import AttendanceEventSubmissionForm from './AttendanceEventSubmissionForm';

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
      error: null,
      course_attendance_events: [],
      sections: [],

      isLoaded: 0,
      selectedAttendanceEvent: null,
      selectedSection: null,
    };

    this._handleAttendanceEventChange = this._handleAttendanceEventChange.bind(this);
    this._handleSectionChange = this._handleSectionChange.bind(this);
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
            isLoaded: this.state.isLoaded + 1,
            course_attendance_events: result,
            selectedAttendanceEvent: result[0],
          });
        },
        // Note: it's important to handle errors here
        // instead of a catch() block so that we don't swallow
        // exceptions from actual bugs in components.
        (error) => {
          this.setState({
            isLoaded: this.state.isLoaded + 1,
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
            isLoaded: this.state.isLoaded + 1,
            sections: result,
            selectedSection: result[0],
          });
        },
        // Note: it's important to handle errors here
        // instead of a catch() block so that we don't swallow
        // exceptions from actual bugs in components.
        (error) => {
          this.setState({
            isLoaded: this.state.isLoaded + 1,
            error,
          });
        }
      );
  }

  _handleAttendanceEventChange(event) {
    const newAttendanceEvent = this.state.course_attendance_events.find(
      (attendance_event) => attendance_event.id == event.target.value
    );
    this.setState({selectedAttendanceEvent: newAttendanceEvent});
  }

  _handleSectionChange(event) {
    console.log('_handleSectionChange');
    console.log(this.state.selectedSection);
    const newSection = this.state.sections.find(
      (section) => section.id == event.target.value
    );
    console.log(newSection);
    this.setState({selectedSection: newSection});
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
              <Form.Control as="select" onChange={this._handleAttendanceEventChange}>
                {course_attendance_events}
              </Form.Control>
            </Form.Group>
          </Col>
          <Col xs="auto">
            <Form.Group controlId="course_section">
              <Form.Label>Section</Form.Label>
              <Form.Control as="select" onChange={this._handleSectionChange}>
                {sections}
              </Form.Control>
            </Form.Group>
          </Col>
        </Form.Row>
      </Form>
    );
  }

  _renderAttendanceEventSubmissionForm() {
    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm url={submitURL} students={students} />
    // Need the submission URL, the list of students
    if (this.state.isLoaded < 2) {
      return <div><p>Loading...</p></div>;
    }
    return (
      <AttendanceEventSubmissionForm
        sectionId={this.state.selectedSection.id}
        eventTitle={this.state.selectedAttendanceEvent.title}
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
