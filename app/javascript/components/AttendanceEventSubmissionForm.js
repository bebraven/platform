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
      answers: [],
    };
    this._handleSubmit = this._handleSubmit.bind(this);
  }

  componentDidMount() {
    this._fetchSubmissionAnswers();
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.submissionId != prevProps.submissionId) {
      this._setState({isLoaded: false});
      this._fetchSubmissionAnswers();
    }
  }

  _fetchSubmissionAnswers() {
    // TODO: This can go in Application whenever we change the submissionID
    // we can have it re-fetch the answers when getting the id itself
    const url = `/attendance_event_submissions/${this.props.submissionId}/answers.json?state=${this.props.state}&section_id=${this.props.sectionId}`;
    console.log(url);
    fetch(url)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            answers: result,
          });
          console.log(result);
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
      return <div><p>Loading...</p></div>;
    }

    if (this.state.error) {
      return <div><p>this.state.error</p></div>;
    }

    // TODO: Handle this.state.error

    // Render form based on this.state.attendance_event_submission_id 
    // <AttendanceEventSubmissionForm url={submitURL} students={students} />
    // Need the submission URL, the list of students
    return (
      <div>
        <h1>Attendance for {this.props.eventTitle}</h1>
        <div>
          {this.state.answers.map(
            (answer) => <AttendanceEventSubmissionAnswer answer={answer} />
          )}
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
