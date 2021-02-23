import Rails from '@rails/ujs';
import React from "react";

import AttendanceEventSubmissionAnswer from './AttendanceEventSubmissionAnswer';

import {
  Button,
  Navbar,
} from 'react-bootstrap';

class AttendanceEventSubmissionForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isLoaded: false,
      isSubmitting: false,
      error: null,
      attendanceEventSubmissionAnswers: null,
      data: {},
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
    //debugger;
    // this.setState({
    //   in_attendance: value,
    //   late: false,
    //   absence_reason: "",
    // });
    // this.props.onChange(props.answer.for_user_id, JSON.stringify(this.state));
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
    // this.setState({
    //   late: !this.state.late,
    // });
    // this.props.onChange(props.answer.for_user_id, JSON.stringify(this.state));
    //debugger;
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
    // this.setState({
    //   absence_reason: event.target.value,
    // });
    // this.props.onChange(props.answer.for_user_id, JSON.stringify(this.state));
    //debugger;
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
    //debugger;
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

    this.setState({isSubmitting: true});
    // JSON.stringify(state)
    const data = this.state.data;

    fetch(
      `/attendance_event_submissions/${this.props.submissionId}/`,
      {
        method: 'PUT',
        body: data,
        headers: {
          'X-CSRF-Token': Rails.csrfToken(),
        },
      },
     )
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isSubmitting: false,
          });
        },
        (error) => {
          this.setState({
            isSubmitting: false,
            error,
          });
        }
      );
  }

  render() {
    if (!this.state.isLoaded) {
      return <div><p>Loading...</p></div>;
    }

    if (this.state.error) {
      return <div><p>this.state.error</p></div>;
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
