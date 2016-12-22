import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { clickHandler, locationHandler, locationError } from '../../web/static/js/geolocation';
import sinon from 'sinon';

describe('geolocation', () => {
  var $;
  jsdom();

  beforeEach(() => {
    $ = jsdom.rerequire('jquery');
    $('body').append('<div id="test"></div>');
  });

  afterEach(() => {
    $('#test').remove();
  });

  describe('clickHandler', () => {
    var geolocationCalled,
        onSpy;

    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target">
          locate me
          <span class="hidden-xs-up loading-indicator"></span>
        </button>
      `);
      geolocationCalled = false;
      window.navigator.geolocation = {
        getCurrentPosition: () => { geolocationCalled = true; }
      };
      onSpy = sinon.spy($.fn, 'on');
    });

    afterEach(() => {
      onSpy.reset();
    });

    it("gets the user's location", () => {
      clickHandler($)({preventDefault: () => {}, target: $('button')[0]});
      assert.isTrue(geolocationCalled);
    });

    it('shows the loading indicator', () => {
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
      clickHandler($)({preventDefault: () => {}, target: $('button')[0]});
      assert.isFalse($('.loading-indicator').hasClass('hidden-xs-up'));
    });

    it('adds a hook to clear the UI state', () => {
      clickHandler($);
      assert.equal(onSpy.args[0][0], 'turbolinks:before-visit');
      onSpy.args[0][1]();
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
    });

  });

  describe('locationHandler', () => {
    const lat = 42.3509448,
          long = -71.0651448;

    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target">
          locate me
          <span class="loading-indicator"></span>
        </button>
      `);
    });

    it('loads the location URL', () => {
      const mockLocation = {};
      locationHandler($, $('button'), mockLocation)({
        coords: {
          latitude: lat,
          longitude: long
        }
      });
      assert.isTrue(new RegExp(`\\?location%5Baddress%5D=${lat},%20${long}`).test(mockLocation.href));
    });
  });

  describe('locationError', () => {
    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target">
          locate me
          <span class="loading-indicator"></span>
        </button>
        <p id="tnm-unavailable-error" class="transit-near-me-error hidden-xs-up">error</p>
        <p id="tnm-permission-error" class="transit-near-me-error hidden-xs-up">error</p>
      `);
    });

    it('hides the loading indicator', () => {
      assert.isFalse($('.loading-indicator').hasClass('hidden-xs-up'));
      locationError($, $('button'))({code: ''});
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
    });

    it('shows an error message on timeout or geolocation failure', () => {
      locationError($, $('button'))({code: 'timeout', TIMEOUT: 'timeout'});
      assert.isFalse($('#tnm-unavailable-error').hasClass('hidden-xs-up'));
    });

    it('shows a single error message', () => {
      locationError($, $('button'))({code: 'timeout', TIMEOUT: 'timeout'});
      locationError($, $('button'))({code: 'permission', PERMISSION_DENIED: 'permission'});
      assert.equal($('.transit-near-me-error').not('.hidden-xs-up').length, 1);
    });

    it('shows an error message if permission is denied', () => {
      locationError($, $('button'))({code: 'permission', PERMISSION_DENIED: 'permission'});
      assert.isFalse($('#tnm-permission-error').hasClass('hidden-xs-up'));
    });
  });
});
