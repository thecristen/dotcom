import { assert } from "chai";
import jsdom from 'mocha-jsdom';
import googleMapsLoaded, { doWhenGooleMapsIsReady } from "../../web/static/js/google-maps-loaded";

describe("google-map-loaded", () => {
  jsdom();

  it("does not execute any callbacks if isMapReady never gets set to true", (done) => {
    googleMapsLoaded();
    window.isMapReady = false;
    let callbackCalled = false;
    doWhenGooleMapsIsReady(() => { callbackCalled = true; });

    // These test are async, call the "done" function after each one -- otherwise the test bleed into each other.
    // Must wait a short amount of time, verify that the callback was not called.
    setTimeout(() => {
      assert.equal(callbackCalled, false);
      done();
    }, 10);
  });

  // this case models the scenario where Google maps loads before app.js
  it("executes the callback when isMapReady was already set to true", (done) => {
    googleMapsLoaded();
    window.isMapReady = true;
    let callbackCalled = false;
    doWhenGooleMapsIsReady(() => {callbackCalled = true;});

    setTimeout(() => {
      assert.equal(callbackCalled, true);
      done();
    }, 10);
  });

  // this case models the scenario where app.js loads before Google maps
  it("executes the callback after this module sets isMapReady to true", (done) => {
    googleMapsLoaded();
    window.isMapReady = false;
    let callbackCalled = false;
    doWhenGooleMapsIsReady(() => {callbackCalled = true;});

    setTimeout(() => {
      window.mapsCallback();
      assert.equal(callbackCalled, true);
      done();
    }, 10);
  });
});
