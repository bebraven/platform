// Asynchronously loads and initializes Boomerangjs. See:
// https://github.com/akamai/boomerang BUT more importantly
// https://akamai.github.io/boomerang/tutorial-loader-snippet.html
//
// Note: the actual initialization of Boomerang is done in the: zzz-last-plugin.js
// built into the compiled boomerang-<version>.js and hosted on S3 as
// per their recommendations. We can't import the boomerang JS as an
// ES6 module. See: https://github.com/akamai/boomerang/issues/117
(function() {
    // Boomerang Loader Snippet version 12
    if (window.BOOMR && (window.BOOMR.version || window.BOOMR.snippetExecuted)) {
        return;
    }

    window.BOOMR = window.BOOMR || {};
    window.BOOMR.snippetStart = new Date().getTime();
    window.BOOMR.snippetExecuted = true;
    window.BOOMR.snippetVersion = 12;

    if (process.env.NODE_ENV !== 'production') {
        // Note: if you need to troubleshoot or enhance our Boomerang / Honeycomb infrastructue setup,
        // you can load the "debug" boomerang JS instead. It'll log a bunch of stuff to the browser console.
        //window.BOOMR.url = "https://boomerangjs.s3.amazonaws.com/boomerang-1.0.0-debug.js";
        window.BOOMR.url = "https://boomerangjs.s3.amazonaws.com/boomerang-1.0.0.js";

        // The Axe utility in the dev env clutters things up by writing console errors, so disable that.
        window.BOOMR.shouldMonitorConsoleErrors = false;

        // Disable XHR auto-instrumenting some development env specific things that may fail
        // and clutter up the console and traces.
        window.BOOMR.xhr_excludes = {
            "/sockjs-node/info":  true // LiveReload socket errors over SSL.
        };

    } else {
        // Note that the following metadata must be set on this for the browser to handle it properly
        // Content-Type: application/javascript
        // Content-Encoding: gzip
        window.BOOMR.url = "https://boomerangjs.s3.amazonaws.com/boomerang-1.0.0.min.js.gz";
    }

    // Note: I've altered this from the original snippet to insert the script after the
    // <meta name="serialized-trace" ...> tag because our compiled Boomerang relies on that
    // to propagate Honeycomb traces.
    var where = document.querySelector('meta[name="serialized-trace"]'),
        // Whether or not Preload method has worked
        promoted = false,
        // How long to wait for Preload to work before falling back to iframe method
        LOADER_TIMEOUT = 3000;

    // Tells the browser to execute the Preloaded script by adding it to the DOM
    function promote() {
        if (promoted) {
            return;
        }

        var script = document.createElement("script");
        script.id = "boomr-scr-as";
        script.src = window.BOOMR.url;

        // Not really needed since dynamic scripts are async by default and the script is already in cache at this point,
        // but some naive parsers will see a missing async attribute and think we're not async
        script.async = true;

        // Note: altered this from original script too.
        where.parentNode.insertBefore(script, where.nextSibling);

        promoted = true;
    }

    // Non-blocking iframe loader (fallback for non-Preload scenarios) for all recent browsers.
    // For IE 6/7, falls back to dynamic script node.
    function iframeLoader(wasFallback) {
        promoted = true;

        var dom, doc = document, bootstrap, iframe, iframeStyle, win = window;

        window.BOOMR.snippetMethod = wasFallback ? "if" : "i";

        // Adds Boomerang within the iframe
        bootstrap = function(parent, scriptId) {
            var script = doc.createElement("script");
            script.id = scriptId || "boomr-if-as";
            script.src = window.BOOMR.url;

            BOOMR_lstart = new Date().getTime();

            parent = parent || doc.body;
            parent.appendChild(script);
        };

        // For IE 6/7, we'll just load the script in the current frame, as those browsers don't support 'about:blank'
        // for an iframe src (it triggers warnings on secure sites).  This means loading on IE 6/7 may cause SPoF.
        if (!window.addEventListener && window.attachEvent && navigator.userAgent.match(/MSIE [67]\./)) {
            window.BOOMR.snippetMethod = "s";

            bootstrap(where.parentNode, "boomr-async");
            return;
        }

        // The rest of this function is IE8+ and other browsers that don't support Preload hints but will work with CSP & iframes
        iframe = document.createElement("IFRAME");

        // An empty frame
        iframe.src = "about:blank";

        // We set title and role appropriately to play nicely with screen readers and other assistive technologies
        iframe.title = "";
        iframe.role = "presentation";

        // Ensure we're not loaded lazily
        iframe.loading = "eager";

        // Hide the iframe
        iframeStyle = (iframe.frameElement || iframe).style;
        iframeStyle.width = 0;
        iframeStyle.height = 0;
        iframeStyle.border = 0;
        iframeStyle.display = "none";

        // Append to the end of the current block. The only thing in the iframe is this script and the
        // serialized-trace is in the parent document, so we don't care where this goes in terms of ensuring it can read that.
        where.parentNode.appendChild(iframe);

        // Try to get the iframe's document object
        try {
            win = iframe.contentWindow;
            doc = win.document.open();
        }
        catch (e) {
            // document.domain has been changed and we're on an old version of IE, so we got an access denied.
            // Note: the only browsers that have this problem also do not have CSP support.

            // Get document.domain of the parent window
            dom = document.domain;

            // Set the src of the iframe to a JavaScript URL that will immediately set its document.domain to match the parent.
            // This lets us access the iframe document long enough to inject our script.
            // Our script may need to do more domain massaging later.
            iframe.src = "javascript:var d=document.open();d.domain='" + dom + "';void(0);";
            win = iframe.contentWindow;

            doc = win.document.open();
        }

        if (dom) {
            // Unsafe version for IE8 compatability. If document.domain has changed, we can't use win, but we can use doc.
            doc._boomrl = function() {
                this.domain = dom;
                bootstrap();
            };

            // Run our function at load.
            // Split the string so HTML code injectors don't get confused and add code here.
            doc.write("<bo" + "dy onload='document._boomrl();'>");
        }
        else {
            // document.domain hasn't changed, regular method should be OK
            win._boomrl = function() {
                bootstrap();
            };

            if (win.addEventListener) {
                win.addEventListener("load", win._boomrl, false);
            }
            else if (win.attachEvent) {
                win.attachEvent("onload", win._boomrl);
            }
        }

        // Finish the document
        doc.close();
    }

    // See if Preload is supported or not
    var link = document.createElement("link");

    if (link.relList &&
        typeof link.relList.supports === "function" &&
        link.relList.supports("preload") &&
        ("as" in link)) {
        window.BOOMR.snippetMethod = "p";

        // Set attributes to trigger a Preload
        link.href = window.BOOMR.url;
        link.rel  = "preload";
        link.as   = "script";

        // Add our script tag if successful, fallback to iframe if not
        link.addEventListener("load", promote);
        link.addEventListener("error", function() {
            iframeLoader(true);
        });

        // Have a fallback in case Preload does nothing or is slow
        setTimeout(function() {
            if (!promoted) {
                iframeLoader(true);
            }
        }, LOADER_TIMEOUT);

        // Note the timestamp we started trying to Preload
        BOOMR_lstart = new Date().getTime();

        // Append our preload link tag. Preload link can go anywhere. It's the <script>
        // element itself that needs to be after the serialized-trace.
        where.parentNode.appendChild(link);
    }
    else {
        // No Preload support, use iframe loader
        iframeLoader(false);
    }

    // Save when the onload event happened, in case this is a non-NavigationTiming browser
    function boomerangSaveLoadTime(e) {
        window.BOOMR_onload = (e && e.timeStamp) || new Date().getTime();
    }

    if (window.addEventListener) {
        window.addEventListener("load", boomerangSaveLoadTime, false);
    }
    else if (window.attachEvent) {
        window.attachEvent("onload", boomerangSaveLoadTime);
    }
})();
