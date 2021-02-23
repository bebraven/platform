import Rails from '@rails/ujs';
import React from "react";

import AttendanceEventSubmissionAnswer from './AttendanceEventSubmissionAnswer';

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

class AttendanceEventSubmissionForm extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      isLoaded: false,
      error: null,
      fellows: [],
    };
  }

  _handleSubmit() {
    // #update ID
    // params: section_id
    // form inputs from Answers
  }

  componentDidMount() {
    fetch("/api/sections/1/users")
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            fellows: result,
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

  render() {
    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm url={submitURL} students={students} />
    // Need the submission URL, the list of students
    return (
      <div>
        <h1>Attendance for {this.props.event_title}</h1>
        <div>
          {this.state.fellows.map((fellow) => <AttendanceEventSubmissionAnswer fellow={fellow} />)}
        </div>
      </div>
    );
  }
}

export default AttendanceEventSubmissionForm;
