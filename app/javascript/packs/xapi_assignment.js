// This JS module is used to save inputs entered by the user
// For an example, see the view used for project_submissions_controller#new
import Rails from '@rails/ujs';

// Passed in from the view using this JS
const CCCV_DATA_ATTR = 'data-course-custom-content-version-id';
const READ_ONLY_ATTR = 'data-read-only';
const PREFILL_DATA_ATTR = 'data-prefill-answers';

// These are the HTML elements we'll attach sendStatement() to
const SUPPORTED_INPUT_ELEMENTS = [
 'input[type="radio"]',
 'input[type="text"]',
 'select',
 'textarea',
];

// This is how we identify the element
const INPUT_ID_ATTR = 'name';

// Main page logic.
document.addEventListener('DOMContentLoaded', () => {
    prefillInputs();

    // If write-enabled, attach listeners to save intermediate responses
    if (document.getElementById('javascript_variables').attributes[READ_ONLY_ATTR].value === "false") {
        attachInputListeners();
    }
});

function getAllInputs() {
    return document.querySelectorAll(SUPPORTED_INPUT_ELEMENTS.join(', '));   
}

function prefillInputs() {
    const inputs = getAllInputs();
    const prefills = document.getElementById('javascript_variables').attributes[PREFILL_DATA_ATTR].value;

    // Note: we don't handle read-only, this is done by the view's CSS.
    inputs.forEach( input => {
        const prefill = prefills[input.name];
        if (!prefill) {
            return; // Nothing previously entered by user.
        } else if (input.type == 'radio' && input.value == prefill.value) {
            input.checked = true; // Check appropriate radio.
        } else  {
            input.value = prefill.value; // Set input value.
        }
    });
}

function attachInputListeners() {
    getAllInputs().forEach(input => { input.onblur = sendStatement });
}

function sendStatement(e) {
    const input = e.target;
    const input_name = input.name;
    const input_value = input.value;

    const course_custom_content_version_id = document.getElementById('javascript_variables').attributes[CCCV_DATA_ATTR].value;

    const data = {
        project_submission_answer: {
            input_name: input_name,
            input_value: input_value,
        },
    };

    // TODO: Ajax call to ProjectSubmissionAnswersController
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
        console.log(response);
    });
}
