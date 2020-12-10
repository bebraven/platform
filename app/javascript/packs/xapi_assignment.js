// This JS module is used to save inputs entered by the user
// For an example, see the view used for project_submissions_controller#new
import Rails from '@rails/ujs';
import { HoneycombXhrSpan } from './honeycomb'
import { HoneycombSpan } from './honeycomb'

const AUTH_HEADER = 'LtiState '+ document.querySelector('meta[name="state"]').content;
const HONEYCOMB_CONTROLLER_NAME = 'javascript.project.submission';

// Passed in from the view using this JS
const SUBMISSION_DATA_ATTR = 'data-project-submission-id';
const COURSE_PROJECT_VERSION_DATA_ATTR = 'data-course-project-version-id';
const READ_ONLY_ATTR = 'data-read-only';
const WRAPPER_DIV_ID = 'custom-content-wrapper';

// These are the HTML elements we'll attach sendStatement() to
const SUPPORTED_INPUT_ELEMENTS = [
 'input[type="radio"]',
 'input[type="text"]',
 'select',
 'textarea',
];

document.addEventListener('DOMContentLoaded', () => {
    const wrapperDiv = document.getElementById(WRAPPER_DIV_ID);
    const isReadOnly = wrapperDiv.attributes[READ_ONLY_ATTR].value;
    const projectSubmissionId = wrapperDiv.attributes[SUBMISSION_DATA_ATTR].value;
    const courseProjectVersionId = wrapperDiv.attributes[COURSE_PROJECT_VERSION_DATA_ATTR].value;

    function getAllInputs() {
        return document.querySelectorAll(SUPPORTED_INPUT_ELEMENTS.join(', '));   
    }
    
    function prefillInputs() {
        const api_url = `/project_submissions/${projectSubmissionId}/project_submission_answers`;

        const honey_span = new HoneycombXhrSpan(HONEYCOMB_CONTROLLER_NAME, 'prefillInputs', {
                                             'id': projectSubmissionId,
                                             'url': api_url,
                                             'readonly': isReadOnly});
    
        const inputs = getAllInputs();
    
        // Mark all inputs as disabled if data-read-only is true.
        if (isReadOnly === "true") {
            inputs.forEach((input) => {
                input.disabled = true;
            });
        }    
    
        fetch(
          api_url,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json;charset=utf-8',
              'Authorization': AUTH_HEADER
            },
          },
         )
        .then((response) => {

            // Convert array of answer objects into map of {input_name: input_value}.
            response.json().then((answers) => {
                const prefills = answers.reduce((map, obj) => {
                    map[obj.input_name] = obj.input_value;
                    return map;
                }, {});
    
                inputs.forEach( input => {
                    // Prefill input values.
                    const prefill = prefills[input.name];
                    if (!prefill) {
                        return; // Nothing previously entered by user.
                    } else if (input.type == 'radio') {
                        if (input.value == prefill) {
                            input.checked = true; // Check appropriate radio.
                        }
                    } else {
                        input.value = prefill; // Set input value.
                    }
                });
            });
    
        })
        .catch((error) => {
            const error_msg = 'Failed to populate previous answers.';
            console.error(error_msg);
            honey_span.addErrorDetails(error_msg, error);
        });
    }
    
    function attachInputListeners() {
        getAllInputs().forEach(input => { input.onblur = sendStatement });
    }
    
    function sendStatement(e) {
        const input = e.target;
        const input_name = input.name;
        const input_value = input.value;
     
        const data = {
            project_submission_answer: {
                input_name: input_name,
                input_value: input_value,
            },
        };
    
        // Ajax call to ProjectSubmissionAnswersController.
        fetch(
          `/course_project_versions/${courseProjectVersionId}/project_submission_answers`,
          {
            method: 'POST',
            body: JSON.stringify(data),
            headers: {
              'X-CSRF-Token': Rails.csrfToken(),
              'Content-Type': 'application/json;charset=utf-8',
              'Authorization': AUTH_HEADER
            },
          },
         )
        .then((response) => {
            // TODO
            console.log(response);
        })
        .catch((error) => {
            // TODO
            console.log(error);
        });
    }

    /////////////////////////////
    // Main page logic.
    /////////////////////////////

    // If no answers have been saved in the past, there won't be a submission or anything to pre-fill.
    if(projectSubmissionId) {
        prefillInputs();
    }

    // If write-enabled, attach listeners to save intermediate responses
    if (isReadOnly === "false") {
        attachInputListeners();
    }

});
