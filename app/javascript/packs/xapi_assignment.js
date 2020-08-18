import tincan from 'tincanjs';

const INPUT_ID_ATTR = 'data-bz-retained';
const USER_OVERRIDE_ID_ATTR = 'data-user-override-id';

export var lrs;

// Connect to the LRS.
// Must be outside all functions, so we can mock out the `lrs` var after module load.
try {
    lrs = new tincan.LRS({
        endpoint: `${window.location.origin}/data/xAPI`,
        // Note: this is the authorization to hit the platform server. It doesn't use this when connecting
        // to the LRS. The LRS authorization header is set by the LrsXapiProxy.
        auth: 'LtiState '+ document.getElementById('javascript_variables').attributes['data-lti-auth-state'].value, 
        allowFail: false
    });
} catch (e) {
    console.log("Failed to setup LRS object: ", e);
    // TODO: do something with error, can't communicate with LRS
    // Send this to Honeycomb?
    // https://app.asana.com/0/1174274412967132/1188732532251833/f
}

// Main page logic.
document.addEventListener('DOMContentLoaded', () => {
    // Attach the xAPI function to all appropriate inputs, and load any existing data.
    const inputs = document.querySelectorAll('textarea,input[type="text"]');
    const javascript_variables = document.getElementById('javascript_variables').attributes;

    const modifyInputElementForViewer = javascript_variables[USER_OVERRIDE_ID_ATTR]
        // TA view
        ? function(input) {
            input.disabled = true;
            input.classList.add('highlighted-user-input');
        }
        // Student view
        : function(input) { input.onblur = sendStatement };

    inputs.forEach(input => modifyInputElementForViewer(input));

    populatePreviousAnswers(populateAnswersCallback);
});

function sendStatement(e) {
    const input = e.target;
    const text = input.value;
    const project_lti_id = document.getElementById('javascript_variables').attributes['data-project-lti-id'].value;
    const activity_id = project_lti_id; // e.g. https://braven.instructure.com/courses/48/assignments/158
    const current_url = `${window.location.origin}${window.location.pathname}`
    const data_input_id = input.attributes[`${INPUT_ID_ATTR}`].value;
    const data_input_url = `${current_url}#/${data_input_id}`;

    // If the input is empty, return early.
    if (!text) {
        return;
    }

    // Form the statement.
    var statement = new tincan.Statement({
        actor: {
            // Note: We overwrite this actor info server-side.
            name: "JS_ACTOR_NAME_REPLACE",
            mbox: "JS_ACTOR_MBOX_REPLACE"
        },
        verb: {
            id: "http://adlnet.gov/expapi/verbs/answered"
        },
        target: {
            id: activity_id,
        },
        result: {
            response: text
        },
        "object": {
            "id": activity_id,
            "objectType": "Activity",
            "definition": {
                "type": "http://adlnet.gov/expapi/activities/cmi.interaction",
                "name": {
                    "und": data_input_id
                },
                "description": {
                    "und": data_input_url
                },
                "interactionType": "fill-in",
            }
        }
    });

    // Send to LRS.
    lrs.saveStatement(
        statement,
        {
            callback: function (err, xhr) {
                if (err !== null) {
                    if (xhr !== null) {
                        console.log("Failed to save statement: " + xhr.responseText + " (" + xhr.status + ")");
                        // TODO: do something with error, didn't save statement
                        // Send this to honeycomb?
                        return;
                    }

                    console.log("Failed to save statement: " + err);
                    // TODO: do something with error, didn't save statement
                    // Send this to honeycomb?
                    return;
                }

                // Success!
                input.setAttribute('data-xapi-statement-id', statement.id);
            }
        }
    );
};

// Callback for populatePreviousAnswers, called recursively.
// `sr` is a `TinCan.StatementsResult`.
function populateAnswersCallback(err, sr) {
    if (err !== null) {
        console.log("Failed to query statements: " + err);
        // TODO: Do something with error, didn't get statements.
        return;
    }

    // Fill empty fields with the first (most recent) response.
    // Ignore all previous responses once a field is non-empty.
    // Note: If you empty a field after filling it, this will populate the last non-empty result.
    sr.statements.forEach(statement => {
        const data_input_id = statement.target.definition.name.und;
        document.querySelectorAll(`[${INPUT_ID_ATTR}="${data_input_id}"]`).forEach(input => {
            if (!input.value) {
                input.value = statement.result.response;
            }
        });
    });

    // Check for more after, so the first result for each field is always used.
    // Note: The TinCanJS docs say to use sr.more !== null, but sr.more is sometimes
    // the empty string "" when there are no more results.
    if (sr.more) {
        // Fetch additional page(s) of statements, recursively.
        lrs.moreStatements({
            url: sr.more,
            callback: populateAnswersCallback
        });
    }
}

// Fill out inputs with previously submitted answers, fetched from the LRS.
function populatePreviousAnswers() {
    const javascript_variables = document.getElementById('javascript_variables').attributes;
    const project_lti_id = javascript_variables['data-project-lti-id'].value;
    const activity_id = project_lti_id; // e.g. https://braven.instructure.com/courses/48/assignments/158

    if (javascript_variables[USER_OVERRIDE_ID_ATTR]) {
        // This is the TA view.
        // lrs.extended is an undocumented member variable that lets us pass in extra parameters to the LRS.
        // See http://rusticisoftware.github.io/TinCanJS/doc/api/latest/files/src_LRS.js.html#l270
        // We remove this param in our proxy before passing the request upstream.
        // By default, if data-student-id isn't set, we fall back to querying the current_user's statements.
        lrs.extended = {
            'user_override_id': javascript_variables[USER_OVERRIDE_ID_ATTR].value
        };
    }

    lrs.queryStatements({
        params: {
            verb: new tincan.Verb({
                id: "http://adlnet.gov/expapi/verbs/answered"
            }),
            agent: new tincan.Agent({
                // Note: We overwrite this actor info server-side.
                name: "JS_ACTOR_NAME_REPLACE",
                mbox: "JS_ACTOR_MBOX_REPLACE"
            }),
            activity: activity_id
        },
        callback: populateAnswersCallback
    });
}
