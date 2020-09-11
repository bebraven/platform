
beforeEach(() => {
    window.BOOMR = {
        plugins: { Errors: { send: jest.fn() } },
        isBoomerangLoaded: true,
        hasSentPageLoadBeacon: jest.fn(),
        subscribe: jest.fn(),
        addVar: jest.fn()
    };
});

test('HoneycombXhrSpan adds standard fields to span', () => {

    window.BOOMR.hasSentPageLoadBeacon.mockReturnValue(true);
    const honeycomb = require('packs/honeycomb.js');
 
    const honey_span = new honeycomb.HoneycombXhrSpan('controller.name', 'action.name', {'somefield': 'somevalue'});
    expect(window.BOOMR.addVar.mock.calls.length).toBe(3);
    expect(window.BOOMR.addVar.mock.calls[0][0]).toBe('javascript.controller');
    expect(window.BOOMR.addVar.mock.calls[0][1]).toBe('controller.name');
    expect(window.BOOMR.addVar.mock.calls[0][2]).toBe(true);
    expect(window.BOOMR.addVar.mock.calls[1][0]).toBe('name');
    expect(window.BOOMR.addVar.mock.calls[1][1]).toBe('controller.name.action.name');
    expect(window.BOOMR.addVar.mock.calls[1][2]).toBe(true);
    expect(window.BOOMR.addVar.mock.calls[2][0]).toBe('controller.name.somefield');
    expect(window.BOOMR.addVar.mock.calls[2][1]).toBe('somevalue');
    expect(window.BOOMR.addVar.mock.calls[2][2]).toBe(true);

});

test('HoneycombSpan adds fields after Boomerang loaded', () => {
    delete window.BOOMR.isBoomerangLoaded;
    const honeycomb = require('packs/honeycomb.js');

    const honey_span = new honeycomb.HoneycombSpan('controller.name.SPAN', 'action.name.SPAN');
    expect(window.BOOMR.addVar.mock.calls.length).toBe(0);

    window.BOOMR.isBoomerangLoaded = true;
    document.dispatchEvent(new Event('onBoomerangLoaded'));    
    expect(window.BOOMR.addVar.mock.calls.length).toBe(2);
});

test('HoneycombXhrSpan adds fields after Boomerang loaded', () => {
    delete window.BOOMR.isBoomerangLoaded;
    const honeycomb = require('packs/honeycomb.js');

    const honey_span = new honeycomb.HoneycombXhrSpan('controller.name', 'action.name');
    expect(window.BOOMR.addVar.mock.calls.length).toBe(0);

    window.BOOMR.hasSentPageLoadBeacon = jest.fn().mockReturnValue(true);
    window.BOOMR.isBoomerangLoaded = true;
    document.dispatchEvent(new Event('onBoomerangLoaded'));    
    expect(window.BOOMR.addVar.mock.calls.length).toBe(2);
});

// Mimic Boomerang having been initialized but not having sent the page load beacon
test('HoneycombXhrSpan adds fields after page load beacon', () => {

    // Save the callback function it subscribes to when page_load_beacon event happens.
    var pageLoadBeaconCallback = null;
    window.BOOMR.subscribe.mockImplementation((eventName, callbackFn) => pageLoadBeaconCallback = callbackFn);
    window.BOOMR.hasSentPageLoadBeacon.mockReturnValue(false);
    const honeycomb = require('packs/honeycomb.js');

    const honey_span = new honeycomb.HoneycombXhrSpan('controller.name', 'action.name', {'somefield': 'somevalue'});
    expect(window.BOOMR.addVar.mock.calls.length).toBe(0);

    // Mimic the page load beacon having happened and the callback executed.
    window.BOOMR.hasSentPageLoadBeacon.mockReturnValue(true);
    pageLoadBeaconCallback();

    expect(window.BOOMR.addVar.mock.calls.length).toBe(3);
});

test('HoneycombXhrSpan adds multiple fields', () => {
    window.BOOMR.hasSentPageLoadBeacon.mockReturnValue(true);
    const honeycomb = require('packs/honeycomb.js');

    const honey_span = new honeycomb.HoneycombXhrSpan('controller.name', 'action.name');
    window.BOOMR.addVar.mockClear();

    honey_span.addFields({ 'field1': 'value1', 'field2': 'value2'});
    expect(window.BOOMR.addVar.mock.calls.length).toBe(2);
    expect(window.BOOMR.addVar.mock.calls[0][0]).toBe('controller.name.field1');
    expect(window.BOOMR.addVar.mock.calls[0][1]).toBe('value1');
    expect(window.BOOMR.addVar.mock.calls[0][2]).toBe(true);
    expect(window.BOOMR.addVar.mock.calls[1][0]).toBe('controller.name.field2');
    expect(window.BOOMR.addVar.mock.calls[1][1]).toBe('value2');
    expect(window.BOOMR.addVar.mock.calls[1][2]).toBe(true);

});

test('sends errors now with standard details when string', () => {
    window.BOOMR.hasSentPageLoadBeacon.mockReturnValue(true);
    const honeycomb = require('packs/honeycomb.js');

    const honey_span = new honeycomb.HoneycombXhrSpan('controller.name', 'action.name');
    window.BOOMR.addVar.mockClear();

    honey_span.addErrorDetails('some message', 'someError');
    expect(window.BOOMR.addVar.mock.calls.length).toBe(1);
    expect(window.BOOMR.addVar.mock.calls[0][0]['error']).toBe('Error');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_log']).toBe('some message');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_action']).toBe('action.name');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_detail']).toContain('someError');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_stacktrace']).toContain('honeycomb.js'); // Top of the stack, created from the string within honeycomb.js
    expect(window.BOOMR.plugins.Errors.send.mock.calls.length).toBe(1);
});

test('sends errors now with standard details when Error object', () => {
    window.BOOMR.hasSentPageLoadBeacon.mockReturnValue(true);
    const honeycomb = require('packs/honeycomb.js');

    const honey_span = new honeycomb.HoneycombXhrSpan('controller.name', 'action.name2');
    window.BOOMR.addVar.mockClear();

    honey_span.addErrorDetails('some message2', new Error('someError2'));
    expect(window.BOOMR.addVar.mock.calls.length).toBe(1);
    expect(window.BOOMR.addVar.mock.calls[0][0]['error']).toBe('Error');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_log']).toBe('some message2');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_action']).toBe('action.name2');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_detail']).toContain('someError2');
    expect(window.BOOMR.addVar.mock.calls[0][0]['error_stacktrace']).toContain('honeycomb.test.js'); // Top of the stack, I just created it.
    expect(window.BOOMR.plugins.Errors.send.mock.calls.length).toBe(1);
});

// TODO: test hte plain honeycombspan and that we can add an error to the pageload beacon
