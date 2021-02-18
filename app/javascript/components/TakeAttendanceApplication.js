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

  componentDidMount() {
    // See: https://reactjs.org/docs/faq-ajax.html
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

  render() {
    return (
      <Form>
        {this._renderEventSelector()}
      </Form>
    );
  }
}

export default TakeAttendanceApplication;
