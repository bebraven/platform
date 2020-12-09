// This JS module is used to save inputs entered by the user
// For an example, see the view used for project_submissions_controller#new
import Rails from '@rails/ujs';

// Passed in from the view using this JS
const SUBMISSION_DATA_ATTR = 'data-project-submission-id';
const READ_ONLY_ATTR = 'data-read-only';
const WRAPPER_DIV_ID = 'custom-content-wrapper';

// These are the HTML elements we'll attach sendStatement() to
const SUPPORTED_INPUT_ELEMENTS = [
 'input[type="radio"]',
 'input[type="text"]',
 'select',
 'textarea',
];

// Main page logic.
document.addEventListener('DOMContentLoaded', () => {
    prefillInputs();

    // If write-enabled, attach listeners to save intermediate responses
    if (document.getElementById(WRAPPER_DIV_ID).attributes[READ_ONLY_ATTR].value === "false") {
        attachInputListeners();
    }
});

function getAllInputs() {
    return document.querySelectorAll(SUPPORTED_INPUT_ELEMENTS.join(', '));   
}

function prefillInputs() {
    const inputs = getAllInputs();
    const wrapperDiv = document.getElementById(WRAPPER_DIV_ID);

    // Mark all inputs as disabled if data-read-only is true.
    if (wrapperDiv.attributes[READ_ONLY_ATTR].value === "true") {
        inputs.forEach((input) => {
            input.disabled = true;
        });
    }

    const project_submission_id = document.getElementById(WRAPPER_DIV_ID).attributes[SUBMISSION_DATA_ATTR].value;
    const api_url = `/project_submissions/${project_submission_id}/project_submission_answers`;

    fetch(
      api_url,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json;charset=utf-8'
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
        // TODO
        console.log(error);
    });

}

function attachInputListeners() {
    getAllInputs().forEach(input => { input.onblur = sendStatement });
}

function sendStatement(e) {
    const input = e.target;
    const input_name = input.name;
    const input_value = input.value;
    const wrapperDiv = document.getElementById(WRAPPER_DIV_ID);

    const course_custom_content_version_id = wrapperDiv.attributes[CCCV_DATA_ATTR].value;

    const data = {
        project_submission_answer: {
            input_name: input_name,
            input_value: input_value,
        },
    };

    // Ajax call to ProjectSubmissionAnswersController.
    fetch(
      `/course_project_versions/${course_custom_content_version_id}/project_submission_answers`,
      {
        method: 'POST',
        body: JSON.stringify(data),
        headers: {
          'X-CSRF-Token': Rails.csrfToken(),
          'Content-Type': 'application/json;charset=utf-8'
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
