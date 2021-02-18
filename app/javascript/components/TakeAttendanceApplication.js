import Rails from '@rails/ujs';
import React from "react";

import {
  Form,
} from 'react-bootstrap';

class TakeAttendanceApplication extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      isLoaded: false,
      error: null,
      course_attendance_events: [],
    };
  }

  // First called when component mounts, e.g. <react_component ... /> from
  // the ERB file. Do data fetching. This can be optimized away by bootstrapping
  // in data as props to the component.
  componentDidMount() {
    // See: https://reactjs.org/docs/faq-ajax.html

    // 1. Fetch attendance events for this course.
    fetch("/api/courses/3/course_attendance_events")
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

    // 3. Fetch the submission based on (1) and (2).
  }

  _renderEventSelector() {
    const options = this.state.course_attendance_events.map(
      (event) => <option value={event.id}>{event.title}</option>
    );
    return (
      <Form.Group controlId="course_attendance_event">
        <Form.Label>Attendance Event</Form.Label>
        <Form.Control as="select">
          {options}
        </Form.Control>
      </Form.Group>
    );
  }

  _renderCourseAttendanceEventForm() {
    // This <Form> has a submit handler that does an AJAX request to get the
    // AttendanceEventSubmission object (e.g, ID) based on the selected
    // course_attendance_event.id, section.id. It updates this.state.
    // attendance_event_submission_id
    return this._renderEventSelector();
  }

  _renderAttendanceEventSubmissionForm() {
    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm id={this.state.attendance_event_submission_id} />
  }

  render() {
    return (
      <Form>
        {this._renderCourseAttendanceEventForm()}
      </Form>
    );
  }
}

export default TakeAttendanceApplication;
