import Rails from '@rails/ujs';
import React, { useState, useEffect } from 'react';

require('react-dom');
window.React2 = require('react');
console.log('HOOKS CHECK!!!!');
console.log(window.React1 === window.React2);

import AttendanceEventSubmissionForm from './AttendanceEventSubmissionForm';

import {
  Col,
  Form,
  Navbar,
} from 'react-bootstrap';

function TakeAttendanceApplication(props) {
  const [isLoading, setIsLoading] = useState(
    // props.attendanceEventSubmission ? false : true,
    false,
  );
  const [courseAttendanceEvent, setCourseAttendanceEvent] = useState(
    props.courseAttendanceEvents[0],
  );
  const [attendanceEventSubmission, setAttendanceEventSubmission] = useState(
    // props.attendanceEventSubmission,
    null, // ignore bootstrapped data, fetch on first render based on courseAttendanceEvent
  );

  const onCourseAttendanceEventChange = event => {
    const newCourseAttendanceEvent = props.courseAttendanceEvents.find(
      (cae) => cae.id == event.target.value,
    );

    setCourseAttendanceEvent(newCourseAttendanceEvent);
    setAttendanceEventSubmission(null);

    // Note: You can move the useEffect logic here and do the fetch and
    // setAttendanceEventSubmission(result) inline.
    // The different is: you won't fetch attendanceEventSubmission the first
    // time this component renders, so you'll have to rely on props or do a
    // fetch explicitly.
    // The logic would be slightly different from useEffect() in that you wouldn't
    // have to check whether attendanceEventSubmission has changed because the
    // event tells you that there's been a change.

  };

  useEffect(() => {
    if (attendanceEventSubmission) {
      return; // Already loaded
    }

    if (isLoading) {
      return; // Already fetching
    }

    setIsLoading(true);

    const url = `/attendance_event_submissions/launch.json?course_attendance_event_id=${courseAttendanceEvent.id}&state=${props.state}`;
  
    console.log(url);

    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    }).then(res => res.json())
      .then(
        (result) => {
          setAttendanceEventSubmission(result);
          setIsLoading(false);
        },
        (error) => {
          setAttendanceEventSubmission(null);
          setIsLoading(false);
        }
      );
  });

  return (
    <div>
      <Navbar
        bg="primary"
        className="justify-content-center"
        sticky="top">
        <Form>
          <Form.Row className="align-items-center">
            <h1>Take Attendance For</h1>
          </Form.Row>
          <Form.Row className="align-items-center">
            <Col xs="auto">
              <Form.Group controlId="course_attendance_event">
                <Form.Label>Event</Form.Label>
                <Form.Control as="select" onChange={onCourseAttendanceEventChange}>
                  {
                    props.courseAttendanceEvents.map(
                      (cae) => <option value={cae.id}>{cae.title}</option>
                    )
                  }
                </Form.Control>
              </Form.Group>
            </Col>
            <Col xs="auto">
              <Form.Group controlId="course_section">
                <Form.Label>Section</Form.Label>
                <Form.Control as="select">
                  <option value={props.section.id}>{props.section.name}</option>
                </Form.Control>
              </Form.Group>
            </Col>
          </Form.Row>
        </Form>
      </Navbar>
      {
        isLoading
          ? <p>Loading attendance form...</p>
          : !attendanceEventSubmission 
            ? <p>Error loading attendance form. Try refreshing.</p> 
            : <AttendanceEventSubmissionForm
              submissionId={attendanceEventSubmission.id}
              eventTitle={courseAttendanceEvent.title}
              sectionId={props.section.id}
              state={props.state}
            />
      }
    </div>
  );
}

// The error without this: https://reactjs.org/warnings/invalid-hook-call-warning.html
// Different React instances: https://github.com/facebook/react/issues/13991
// The fix (doesn't fix React instances, WTF?): https://github.com/shakacode/react_on_rails/issues/1198
export default props => <TakeAttendanceApplication {...props} />;
