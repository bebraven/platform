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

  componentDidMount() {
    this._fetchFellowsInSection();
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.sectionId != prevProps.sectionId) {
      this.setState({isLoaded: false});
      this._fetchFellowsInSection();
    }
  }

  _fetchFellowsInSection() {
    fetch(`/api/sections/${this.props.sectionId}/users`)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            fellows: result,
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

  _handleSubmit() {
    // #update ID
    // params: section_id
    // form inputs from Answers
  }

  render() {
    if (!this.state.isLoaded) {
      return <div><p>Loading..</p></div>;
    }

    // TODO: Handle this.state.error
    
    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm url={submitURL} students={students} />
    // Need the submission URL, the list of students
    return (
      <div>
        <h1>Attendance for {this.props.eventTitle}</h1>
        <div>
          {this.state.fellows.map((fellow) => <AttendanceEventSubmissionAnswer fellow={fellow} />)}
        </div>
      </div>
    );
  }
}

export default AttendanceEventSubmissionForm;
