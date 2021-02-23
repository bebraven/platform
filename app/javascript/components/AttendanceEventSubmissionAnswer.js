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

class AttendanceEventSubmissionAnswer extends React.Component {
  _renderAttendanceDetails() {
    switch(this.props.answer.in_attendance) {
      case true:
        return (
          <Form.Group controlId="isLateCheckbox">
            <Form.Check
              name={this.props.name}
              type="checkbox"
              label="Late?"
              checked={this.props.answer.late}
              onChange={this.props.onLateChange}
            />
          </Form.Group>
        );
      case false:
        return (
          <Form.Group controlId="absenceReason">
            <Form.Label srOnly>Reason for absence?</Form.Label>
            <Form.Control
              name={this.props.name}
              as="select"
              value={this.props.answer.absence_reason}
              onChange={this.props.onAbsenceReasonChange}
            >
              <option value="" disabled>Reason for absence?</option>
              {absenceReasons.map( (reason) => <option>{reason}</option> )}
            </Form.Control>
          </Form.Group>
        );
      default:
        return null;
    }
  }

  render() {
    //debugger;
    return (
      <Row>
        <Col>
          {this.props.answer.for_user_name}
        </Col>
        <Col>
        <ToggleButtonGroup
          name={this.props.name}
          type="radio"
          value={this.props.answer.in_attendance}
          onChange={this.props.onInAttendanceChange}
        >
          <ToggleButton value={true}>Present</ToggleButton>
          <ToggleButton value={false}>Absent</ToggleButton>
        </ToggleButtonGroup>
        </Col>
        <Col>
          {this._renderAttendanceDetails()}
        </Col>
        <Col>
          {
            this.props.answer.in_attendance == true || this.props.answer.in_attendance == false
            ? <Button
                variant="secondary"
                name={this.props.name}
                onClick={this.props.onClear}
              >
              Clear
            </Button>
            : null
          }
        </Col>
      </Row>
    );
  }
}

export default AttendanceEventSubmissionAnswer;
