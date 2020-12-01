// This JS module is used to save inputs entered by the user
// For an example, see the view used for project_submissions_controller#new

// Passed in from the view using this JS
const BCCCV_DATA_ATTR = 'data-base-course-custom-content-version-id';
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
    if (!document.getElementById('javascript_variables').attributes[READ_ONLY_ATTR]) {
        attachInputListeners();
    }
});

function getAllInputs() {
    // TODO: Use SUPPORTED_INPUT_ELEMENTS
    return document.querySelectorAll('textarea, input[type="text"], input[type="radio"], select');   
}

function prefillInputs() {
    const inputs = getAllInputs();
    const prefills = document.getElementById('javascript_variables').attributes[PREFILL_DATA_ATTR];

    // Note: we don't handle read-only, this is done by the view's CSS
    inputs.forEach( input => {
        const prefill = prefills[input.name];
        if (!prefill) {
            return; // Nothing previously entered by user
        } else if (input.type == 'radio' && input.value = prefill.value) {
            input.checked = true; // Check appropriate radio
        } else  {
            input.value = prefill.value; // Set input value
        }
    });
}

function attachInputListeners() {
    getAllInputs().forEach(input => { input.onblur = sendStatement });
}

function sendStatement(e) {
    const input = e.target;
    const input_name = input.attributes[`${INPUT_ID_ATTR}`].value;
    const input_value = input.value;

    const params = {
        project_answer_input_name: input_name,
        project_answer_input_value: input_value,
        base_course_custom_content_version: document.getElementById('javascript_variables').attributes[BCCCV_DATA_ATTR].value;

    };

    // TODO: Ajax call to ProjectSubmissionAnswersController
}
