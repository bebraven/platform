import { isErrorObject } from '../utils/errorutils';

/*
 * Base class for various types of HoneycombSpan wrappers exported in this module.
 */
class HoneycombSpanBase {

    /*
     * Instantiate this with a particular "controller" and "action".
     * I'm using these terms to mimic Rails where the "controller" is the general service we're
     * dealing with, such as xAPI request/responses for a Project. The "action" is what
     * we're currenly doing. E.g. populating previous answers. The concept maps to the Rails concept
     * of the particular method we're calling on the controller.
     *
     * @param {Function} functionWrapper a function that takes a function as an argument and wraps it in
     *                                   extra logic before (and after) executing it. All public methods 
     *                                   will be wrapped in this if it's specified.
     */
    constructor(controller, action, fields = {}, prefixFieldsWithControllerName = true, functionWrapper = null) {
        this.controller = controller;
        this.action = action;
        this.name = `${controller}.${action}`;
        this.prefixFieldsWithControllerName = prefixFieldsWithControllerName;
        this.functionWrapper = functionWrapper;
 
        this.getFieldName = function(key) {
            return (this.prefixFieldsWithControllerName ? `${this.controller}.${key}` : key);
        }

        this.runAfterBoomerangLoaded = function(f) {
            if (window.BOOMR && window.BOOMR.isBoomerangLoaded) { 
                if (functionWrapper) {
                    functionWrapper(f);
                } else {
                    f();
                }
            } else {
                // In the real world, this should only fire once, but in jest tests it can be fired multiple times. Hence the "once" option.
                document.addEventListener("onBoomerangLoaded", () => this.runAfterBoomerangLoaded(f), { once: true });
            }
        }

        this.runAfterBoomerangLoaded(() => {
            // Standard fields that should be added to every span.
            // Don't prefix these. They're common to all "controllers" 
            window.BOOMR.addVar('javascript.controller', controller, true);
            window.BOOMR.addVar('name', this.name, true);
     
            this.addFields(fields);
        });
    }

    /*
     * Adds a field to the current span.
     */
    addField(key, value) {
        this.runAfterBoomerangLoaded(() => {
            window.BOOMR.addVar(this.getFieldName(key), value, true);
        });
    }

    /*
     * Adds multiple fields to the current span.
     */
    addFields(fields) {
        this.runAfterBoomerangLoaded(() => {
            for (const key of Object.keys(fields)) {
                this.addField(key, fields[key]);
            }
        });
    }

    /*
     * Adds a standard Error object to the current span and sends the beacon immediately.
     *
     * Most errors will be picked up and logged automatically, but not with the easiest to read and
     * query for data. This pulls out some convenient details from the error and adds them as fields.
     */
    addErrorDetails(log_msg, e) {
        this.runAfterBoomerangLoaded(() => {
             // Some things, like the LRS.saveStatement() calls, don't send actual error objects so we
             // can't get the stacktrace, etc. Artificially create an Error object so the stacktrace is there.
             if (isErrorObject(e) == false) { e = new Error(JSON.stringify(e)) }

             // Don't prefix these field names, they're standard.
             const error_data = {
                 error: e.name,
                 error_log: log_msg,
                 error_detail: e.toString(),
                 error_action: this.action,
                 error_stacktrace: e.stack
             };
             window.BOOMR.addVar(error_data, null, true);
             window.BOOMR.plugins.Errors.send(e); // Force the beacon to go out.
        });
    } 
}

/*
 * Wrapper for Boomerang AutoXHR plugin beacons (also handles Fetch requests) to treat them
 * as a "span" in Honeycomb. This allows us to more easily add our own instrumentation details 
 * to what the automatic beacon provides and ensure that it ends up on the correct beacon. 
 * See here for documentation on the AutoXHR plugin behavior:
 *     https://akamai.github.io/boomerang/BOOMR.plugins.AutoXHR.html
 *
 * Example Usage: 
 * const honey_span = new HoneycombXhrSpan('controller.name', 'action.name', {
 *    'field1.to.add': 'value1', 
 *    'field2.to.add': 'value2'});
 *
 * try {
 *
 * ... kick off XHR or Fetch request ...
 *
 *     honey_span.addField('another.field.to.add', 'itsValue');
 *
 * } catch(err) {
 *     honey_span.honey_span.addErrorDetails('error message about what happened', err);
 * }
 *
 * That's it! The span info will automatically go out in the XHR beacon.
 *
 * Note: for XHR/Fetch requests that start during page load, the AutoXHR plugin will capture the timing
 * information, but this wrapper ensures that the instrumentation we add goes in the XHR beacon
 * that is sent after the page load beacon. This whole concept of the page load beacon is very
 * important to understand when dealing with Boomerang.
 *
 * Note2: if you enhance this class, try to avoid translating built-in Boomerang fields (aka vars)
 * into normalized ones that we use for Rails instrumentation. Let the honeycombjscontroller do the
 * translation when possible.
 */
export class HoneycombXhrSpan extends HoneycombSpanBase {

    /*
     * See the base class for info on the params.
     *
     * Another way to think about the "action" HoneycombXhrSpan is that it's the AJAX call we're making,
     * which may have callbacks and other function's to accomplish it, but all instrumentation added
     * in those should be part of the overall request/response.
     */
    constructor(controller, action, fields = {}, prefixFieldsWithControllerName = true) {
      // Define a wrapper function that delays executing the passed in function until the page load beacon has
      // gone out. Pass this to the base class so that it wraps all public methods with this delay.
      // We need to do this so that the fields end up in the XHR beacon and not the page load beacon so they 
      // end up in that Honeycomb span and don't get split across multiple.
      const runAfterPageLoadBeacon = function(f) {
          if (window.BOOMR.hasSentPageLoadBeacon()) {
              f();
          } else {
              window.BOOMR.subscribe("page_load_beacon", () => runAfterPageLoadBeacon(f), { once: true } );
          }
      };

      super(controller, action, fields, prefixFieldsWithControllerName, runAfterPageLoadBeacon);
    }
}

/*
 * Wrapper for adding extra instrumentation to any Boomerang beacon so that it will go into the corresponding
 * Honeycomb span once the beacon is sent. This can be used to add fields to the page load beacon, or
 * log errors during page load.
 *
 * Example Usage: 
 * const honey_span = new HoneycombSpan('controller.name', 'action.name');
 * try {
 *     ... something not necessarily related to an Ajax call using XHR or Fetch, like initializing a component ...
 *     honey_span.addField('key.name.of.something.interesting', 'interesting.value'); 
 * } catch (err) {
 *     const error_msg = "something went wrong";
 *     honey_span.addErrorDetails(error_msg, err);
 * }
 *
 * Note: if you need a mechanism to manually trace some unit-of-work, add something to this class that uses
 * this: https://akamai.github.io/boomerang/tutorial-howto-measure-arbitrary-events.html
 */
export class HoneycombSpan extends HoneycombSpanBase {

    constructor(controller, action, fields = {}, prefixFieldsWithControllerName = true) {
      super(controller, action, fields, prefixFieldsWithControllerName);
    }

}
