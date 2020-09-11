import tincan from 'tincanjs';
const real_tincan = jest.requireActual('tincanjs');

jest.mock('tincanjs');

beforeEach(() => {
    // Set up our document 
    document.head.innerHTML = '<meta name="state" content="test">';
    document.body.innerHTML =
        '<div id="javascript_variables" data-project-lti-id="1"></div>' +
        '<input type="text" data-bz-retained="test-id">' +
        '<textarea data-bz-retained="test-id-2"></textarea>';
});

test('set input value to matching statement response', () => {
    // Note: this has side-effects, both from top-level code and from code run during in the
    // ready callback.
    const xapi_assignment = require('packs/xapi_assignment');

    // Define a mock implementation.
    xapi_assignment.lrs.queryStatements.mockImplementation((cfg) => {
        const sr = real_tincan.StatementsResult.fromJSON(
            JSON.stringify({
                statements: [
                    {
                        result: {
                            response: 'test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    }
                ]
            })
        );
        cfg.callback(null, sr);
    });

    // Clear the mock, so the side-effects from the ready event callback go away.
    xapi_assignment.lrs.queryStatements.mockClear()
    // Then fire the event again, as if the document has just loaded.
    document.dispatchEvent(new Event('DOMContentLoaded'));

    // Test.
    expect(xapi_assignment.lrs.queryStatements.mock.calls.length).toBe(1);
    expect(xapi_assignment.lrs.moreStatements.mock.calls.length).toBe(0);
    expect(document.body.querySelector('[data-bz-retained="test-id"]').value).toContain('test value');
});

test('uses the first (most recent) statement', () => {
    // Note: this has side-effects, both from top-level code and from code run during in the
    // ready callback.
    const xapi_assignment = require('packs/xapi_assignment');

    // Define a mock implementation.
    xapi_assignment.lrs.queryStatements.mockImplementation((cfg) => {
        const sr = real_tincan.StatementsResult.fromJSON(
            JSON.stringify({
                statements: [
                    {
                        result: {
                            response: 'latest test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    },
                    {
                        result: {
                            response: 'middle test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    },
                    {
                        result: {
                            response: 'oldest test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    }
                ]
            })
        );
        cfg.callback(null, sr);
    });

    // Clear the mock, so the side-effects from the ready event callback go away.
    xapi_assignment.lrs.queryStatements.mockClear()
    // Then fire the event again, as if the document has just loaded.
    document.dispatchEvent(new Event('DOMContentLoaded'));

    // Test.
    expect(xapi_assignment.lrs.queryStatements.mock.calls.length).toBe(1);
    expect(xapi_assignment.lrs.moreStatements.mock.calls.length).toBe(0);
    expect(document.body.querySelector('[data-bz-retained="test-id"]').value).toContain('latest test value');
});

test('uses the correct matching statement when there are multiple inputs', () => {
    // Note: this has side-effects, both from top-level code and from code run during in the
    // ready callback.
    const xapi_assignment = require('packs/xapi_assignment');

    // Define a mock implementation.
    xapi_assignment.lrs.queryStatements.mockImplementation((cfg) => {
        const sr = real_tincan.StatementsResult.fromJSON(
            JSON.stringify({
                statements: [
                    {
                        result: {
                            response: 'latest test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    },
                    {
                        result: {
                            response: 'another test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    },
                    {
                        result: {
                            response: 'latest test value for the textarea'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id-2'
                                }
                            }
                        }
                    },
                    {
                        result: {
                            response: 'oldest test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id-2'
                                }
                            }
                        }
                    }
                ]
            })
        );
        cfg.callback(null, sr);
    });

    // Clear the mock, so the side-effects from the ready event callback go away.
    xapi_assignment.lrs.queryStatements.mockClear()
    // Then fire the event again, as if the document has just loaded.
    document.dispatchEvent(new Event('DOMContentLoaded'));

    // Test.
    expect(xapi_assignment.lrs.queryStatements.mock.calls.length).toBe(1);
    expect(xapi_assignment.lrs.moreStatements.mock.calls.length).toBe(0);
    expect(document.body.querySelector('[data-bz-retained="test-id"]').value).toContain('latest test value');
    expect(document.body.querySelector('[data-bz-retained="test-id-2"]').value).toContain('latest test value for the textarea');
});

test('fetches more pages if needed', () => {
    // Note: this has side-effects, both from top-level code and from code run during in the
    // ready callback.
    const xapi_assignment = require('packs/xapi_assignment');

    // Define a mock implementation.
    xapi_assignment.lrs.queryStatements.mockImplementation((cfg) => {
        const sr = real_tincan.StatementsResult.fromJSON(
            JSON.stringify({
                statements: [
                    {
                        result: {
                            response: 'test value'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    }
                ],
                more: "https://example.com/more"
            })
        );
        cfg.callback(null, sr);
    });
    xapi_assignment.lrs.moreStatements.mockImplementationOnce((cfg) => {
        const sr = real_tincan.StatementsResult.fromJSON(
            JSON.stringify({
                statements: [
                    {
                        result: {
                            response: 'test value second page'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id-no-match'
                                }
                            }
                        }
                    }
                ],
                more: "https://example.com/more/2"
            })
        );
        cfg.callback(null, sr);
    });
    xapi_assignment.lrs.moreStatements.mockImplementation((cfg) => {
        const sr = real_tincan.StatementsResult.fromJSON(
            JSON.stringify({
                statements: [
                    {
                        result: {
                            response: 'test value third page'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id'
                                }
                            }
                        }
                    },
                    {
                        result: {
                            response: 'textarea test value third page'
                        },
                        target: {
                            definition: {
                                name: {
                                    und: 'test-id-2'
                                }
                            }
                        }
                    }
                ]
            })
        );
        cfg.callback(null, sr);
    });

    // Clear the mock, so the side-effects from the ready event callback go away.
    xapi_assignment.lrs.queryStatements.mockClear()
    // Then fire the event again, as if the document has just loaded.
    document.dispatchEvent(new Event('DOMContentLoaded'));

    // Test.
    expect(xapi_assignment.lrs.queryStatements.mock.calls.length).toBe(1);
    expect(xapi_assignment.lrs.moreStatements.mock.calls.length).toBe(2);
    expect(document.body.querySelector('[data-bz-retained="test-id"]').value).toContain('test value');
    expect(document.body.querySelector('[data-bz-retained="test-id-2"]').value).toContain('textarea test value third page');
});

test('inputs are set to read-only in TA view', () => {
    // Set up our document for TA view.
    document.head.innerHTML = '<meta name="state" content="test">';
    document.body.innerHTML =
        '<div id="javascript_variables" data-project-lti-id="1" data-user-override-id="10"></div>' +
        '<input type="text" data-bz-retained="test-id">' +
        '<textarea data-bz-retained="test-id-2"></textarea>';
    // Note: this has side-effects, both from top-level code and from code run during in the
    // ready callback.
    const xapi_assignment = require('packs/xapi_assignment');
    // Make sure the ready event fires.
    document.dispatchEvent(new Event('DOMContentLoaded'));

    // Test.
    expect(document.body.querySelector('[data-bz-retained="test-id"]').disabled).toBe(true);
    expect(document.body.querySelector('[data-bz-retained="test-id-2"]').disabled).toBe(true);
});

test('uses the overridden student ID if it is passed in', () => {
    // Set up our document for TA view.
    document.head.innerHTML = '<meta name="state" content="test">';
    document.body.innerHTML =
        '<div id="javascript_variables" data-project-lti-id="1" data-user-override-id="10"></div>' +
        '<input type="text" data-bz-retained="test-id">' +
        '<textarea data-bz-retained="test-id-2"></textarea>';
    // Note: this has side-effects, both from top-level code and from code run during in the
    // ready callback.
    const xapi_assignment = require('packs/xapi_assignment');
    // Make sure the ready event fires.
    document.dispatchEvent(new Event('DOMContentLoaded'));

    // Test.
    expect(document.body.querySelector('#javascript_variables').attributes['data-user-override-id'].value).toBe("10");
    expect(xapi_assignment.lrs.extended).toStrictEqual({user_override_id: "10"});
});
