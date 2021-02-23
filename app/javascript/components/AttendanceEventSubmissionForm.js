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
      isLoaded: 0,
      error: null,
      fellows: [],
      answers: [],
    };
    this._handleSubmit = this._handleSubmit.bind(this);
  }

  componentDidMount() {
    this._fetchFellowsInSection();
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.sectionId != prevProps.sectionId) {
      this.setState({isLoaded: 0});
      this._fetchFellowsInSection();
    }
  }

  _fetchFellowsInSection() {
    fetch(`/api/sections/${this.props.sectionId}/users`)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: this.state.isLoaded + 1,
            fellows: result,
          });
        },
        (error) => {
          this.setState({
            isLoaded: this.state.isLoaded + 1,
            error,
          });
        }
      );

    // TODO: This can be reduced to a single fetch if we return all the 
    // fellows in the section, even those without an entry
    fetch(`/api/attendance_event_submissions/${this.props.submissionId}/answers`)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: this.state.isLoaded + 1,
            answers: result,
          });
        },
        (error) => {
          this.setState({
            isLoaded: this.state.isLoaded + 1,
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
    if (this.state.isLoaded < 2) {
      return <div><p>Loading...</p></div>;
    }

    // TODO: Handle this.state.error

    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm url={submitURL} students={students} />
    // Need the submission URL, the list of students
    return (
      <div>
        <h1>Attendance for {this.props.eventTitle}</h1>
        <div>
          {this.state.fellows.map((fellow) => <AttendanceEventSubmissionAnswer
            fellow={fellow}
            answer={this.state.answers.find((answer) => answer.for_user_id == fellow.id)}
          />)}
        </div>
        <Navbar
        bg="transparent"
        className="justify-content-end"
        fixed="bottom">
          <Button variant="primary" type="submit" onClick={this._handleSubmit}>Save</Button>
        </Navbar>
      </div>

    );
  }
}

export default AttendanceEventSubmissionForm;
