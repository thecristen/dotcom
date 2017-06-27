import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { default as geolocation, clickHandler, locationHandler, locationError } from '../../web/static/js/geolocation';
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

  describe('geolocation', () => {
    beforeEach(() => {
      $('#test').html(`
          <span class="loading-indicator"></span>
      `);
    });

    it('adds a hook to clear the UI state if geolocation is enabled', () => {
      const spy = sinon.spy();
      geolocation($, {addEventListener: spy}, {geolocation: true});
      assert.equal(spy.args[0][0], 'turbolinks:before-visit');
      spy.args[0][1](); // call the aEL callback
      assert.equal($('.loading-indicator').css('display'), 'none');
    });

    it('adds a class to the HTML element if geolocation is disabled', () => {
      geolocation($, {documentElement: document.documentElement}, {});
      assert.equal(document.documentElement.className, " geolocation-disabled");
    });
  });

  describe('clickHandler', () => {
    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target" data-id="test">
          locate me
          <span class="hidden-xs-up loading-indicator"></span>
        </button>
        <div id="test-geolocation-error"></div>
      `);
      window.navigator.geolocation = {
        getCurrentPosition: () => {}
      };
    });

    it("gets the user's location", () => {
      var geolocationCalled = false;
      clickHandler($,
        { geolocation: {
            getCurrentPosition: () => { geolocationCalled = true; }
          }
        }
      )({preventDefault: () => {}, target: $('button')[0]});
      assert.isTrue(geolocationCalled);
    });

    it('shows the loading indicator', () => {
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
      clickHandler($,
        { geolocation: {
            getCurrentPosition: () => {}
          }
        }
      )({preventDefault: () => {}, target: $('button')[0]});
      assert.isFalse($('.loading-indicator').hasClass('hidden-xs-up'));
    });
  });

  describe('locationHandler', () => {
    const lat = 42.3509448,
          long = -71.0651448;

    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target" data-id="test" data-action="reload" data-field="location[address]">
          locate me
          <span class="loading-indicator"></span>
        </button>
        <div id="test-geolocation-error"></div>
      `);
    });

    it('triggers a geolocation:complete event with the location information', (done) => {
      const geolocationCallback = (e, location) => {
        assert.deepEqual(location.coords, { latitude: lat, longitude: long })
        done();
      }
      $('#test').on('geolocation:complete', geolocationCallback);
      geolocation($, document, { geolocation: true });

      locationHandler($, $('button'), $('#test-geolocation-error'))({
        coords: {
          latitude: lat,
          longitude: long
        }
      });
    });

    it('hides the loading indicator on geolocation:complete', (done) => {
      geolocation($,
        document,
        { geolocation: {
            getCurrentPosition: (success, error) => {
              success({ coords: { latitude: 0, longitude: 0 } });
            }
          }
        });
      $('#test').find('.loading-indicator').removeClass('hidden-xs-up');
      $('#test').parent().on('geolocation:complete', () => {
        assert.isTrue($('#test').find('.loading-indicator').hasClass('hidden-xs-up'));
        done();
      });

      $('#test button').trigger('click');
    });
  });

  describe('locationError', () => {
    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target" data-id="test">
          locate me
          <span class="loading-indicator"></span>
        </button>
        <div class="transit-near-me-error">flash error</div>
        <div id="test-geolocation-error"></div>
      `);
    });

    it('hides the loading indicator', () => {
      assert.isFalse($('.loading-indicator').hasClass('hidden-xs-up'));
      locationError($, $('button'), $('#test-geolocation-error'))({code: ''});
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
    });

    it('shows an error message on timeout or geolocation failure', () => {
      locationError($, $('button'), $('#test-geolocation-error'))({code: 'timeout', TIMEOUT: 'timeout'});
      assert.isFalse($('#tnm-geolocation-error').hasClass('hidden-xs-up'));
    });

    it('shows a single error message', () => {
      locationError($, $('button'), $('#test-geolocation-error'))({code: 'permission', PERMISSION_DENIED: 'permission'});
      assert.equal($('.transit-near-me-error').not('.hidden-xs-up').length, 1);
    });

    it('shows an error message if permission is denied', () => {
      locationError($, $('button'), $('#test-geolocation-error'))({code: 'permission', PERMISSION_DENIED: 'permission'});
      assert.isFalse($('#tnm-geolocation-error').hasClass('hidden-xs-up'));
    });
  });
});
