import tincan from 'tincanjs';

// Connect to the LRS.
var lrs;

try {
    lrs = new tincan.LRS({
        // Note: We overwrite this auth server-side.
        endpoint: `${window.location.origin}/data/xAPI`,
        username: "JS_USERNAME_REPLACE",
        password: "JS_PASSWORD_REPLACE",
        allowFail: false
    });
} catch (e) {
    console.log("Failed to setup LRS object: ", e);
    // TODO: do something with error, can't communicate with LRS
    // Send this to Honeycomb?
}

function sendStatement(e) {
    const input = e.target;
    const text = input.value;
    const name = input.attributes['data-bz-retained'].value;
    const object_id = `${window.location.origin}${window.location.pathname}#/${name}`;

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
            id: object_id,
        },
        result: {
            response: text
        },
        "object": {
            "id": object_id,
            "objectType": "Activity",
            "definition": {
                "type": "http://adlnet.gov/expapi/activities/cmi.interaction",
                "name": {
                    "und": name
                },
                "description": {
                    "und": name
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


// Attach the xAPI function to all appropriate inputs.
var inputs = document.querySelectorAll('textarea,input[type="text"]');

inputs.forEach(input => {
    input.onblur = sendStatement;
});
