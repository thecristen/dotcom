import { assert } from "chai";
import jsdom from 'mocha-jsdom';
import googleMapsLoaded, { doWhenGooleMapsIsReady, getCallbacks } from "../../web/static/js/google-maps-loaded";

describe("google-map-loaded", () => {
  jsdom();

  it("accumulates callbacks when maps is not ready", (done) => {
    // initialize
    googleMapsLoaded();
    window.isMapReady = false;

    // add two callbacks
    doWhenGooleMapsIsReady(() => true);
    doWhenGooleMapsIsReady(() => true);

    assert.equal(getCallbacks().length, 2);

    // these test are async, call the "done" function after each one -- otherwise the test bleed into each other
    done();
  });

  it("callback called when maps is already ready", (done) => {
    // initialize
    let callbackCalled = false;
    googleMapsLoaded();
    window.isMapReady = true;

    // register a callback that will change a local variable
    doWhenGooleMapsIsReady(() => {
      callbackCalled = true;
    });

    // wait a short amount of time, verify that the callback got called because the global had been preset
    setTimeout(() => {
      assert.equal(callbackCalled, true);
      assert.equal(getCallbacks().length, 0);
      done();
    }, 10);
  });

  it("callback called after main callback triggered", (done) => {
    // initialize
    window.isMapReady = false;
    let callbackCalled = false;
    googleMapsLoaded();

    // register a callback that will change a local variable
    doWhenGooleMapsIsReady(() => {
      callbackCalled = true;
    });

    // verify that the function was not yet called because the global has been preset to false
    setTimeout(() => {
      assert.equal(getCallbacks().length, 1);
    }, 10)

    // wait a short amount of time, now we expect that the function was called
    setTimeout(() => {
      // simulate google calling the global callback
      window.mapsCallback();
      assert.equal(callbackCalled, true);
      assert.equal(getCallbacks().length, 0);
      done();
    }, 20);
  });
});
