import Rails from '@rails/ujs';
import React from "react";

import {
  Button,
  Col,
  Form,
  ToggleButton,
  ToggleButtonGroup,
  Row,
} from 'react-bootstrap';

class AttendanceEventSubmissionAnswer extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      in_attendance: props.answer && props.answer.in_attendance,
      late: props.answer && props.answer.late || false,
      absence_reason: props.answer && props.answer.absence_reason || "",
    };

    this._handleChange = this._handleChange.bind(this);
    this._resetInAttendance = this._resetInAttendance.bind(this);
    this._handleLateChange = this._handleLateChange.bind(this);
    this._handleAbsenceReasonChange = this._handleAbsenceReasonChange.bind(this);
  }

  _handleChange(value) {
    this.setState({
      in_attendance: value,
      late: false,
      absence_reason: "",
    });
  }

  _resetInAttendance() {
    this.setState({
      in_attendance: null,
      late: false,
      absence_reason: "",
    });
  }

  _renderAttendanceDetails() {
    const absenceReasons = [
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
            <Form.Check type="checkbox" label="Late?" checked={this.state.late} onChange={this._handleLateChange}/>
          </Form.Group>
        );
      case false:
        return (
          <Form.Group controlId="absenceReason">
            <Form.Label srOnly>Reason for absence?</Form.Label>
            <Form.Control as="select" value={this.state.absence_reason} onChange={this._handleAbsenceReasonChange} >
            <option value="" disabled>Reason for absence?</option>
              {absenceReasons.map( (reason) => <option>{reason}</option> )}
            </Form.Control>
          </Form.Group>
        );
      default:
        return null;
    }
  }

  _handleAbsenceReasonChange(event) {
    this.setState({
      absence_reason: event.target.value,
    });
  }

  _handleLateChange(event) {
    this.setState({
      late: !this.state.late,
    });
  }

  _renderAttendanceReset() {
    if (this.state.in_attendance == null) {
      return null;
    }
    return (
      <Button variant="secondary" onClick={this._resetInAttendance}>
        Clear
      </Button>
    );
  }

  render() {
    return (
      <Row className="align-middle">
        <Col>
          {this.props.answer.for_user_name}
        </Col>
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
}

export default AttendanceEventSubmissionAnswer;
