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
    var geolocationCalled;

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
  });

  describe('locationHandler', () => {
    const lat = 42.3509448,
          long = -71.0651448;
    var onSpy;

    afterEach(() => {
      window.Turbolinks = undefined;
      onSpy.reset();
    });

    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target">
          locate me
          <span class="loading-indicator"></span>
        </button>
      `);
      onSpy = sinon.spy($.fn, 'on');
    });

    it('hides the loading indicator', () => {
      window.Turbolinks = {visit: () => {}};
      assert.isFalse($('.loading-indicator').hasClass('hidden-xs-up'));
      locationHandler($, $('button'))({
        coords: {
          latitude: lat,
          longitude: long
        }
      });
      assert.equal(onSpy.args[0][0], 'turbolinks:before-visit');
      onSpy.args[0][1]();
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
    });

    it('loads the location URL', (done) => {
      window.Turbolinks = {
        visit: (url) => {
          assert.isTrue(new RegExp(`\\?location%5Baddress%5D=${lat},%20${long}`).test(url));
          done();
        }
      };
      locationHandler($, $('button'))({
        coords: {
          latitude: lat,
          longitude: long
        }
      });
    });
  });

  describe('locationError', () => {
    beforeEach(() => {
      $('#test').html(`
        <button data-geolocation-target="target">
          locate me
          <span class="loading-indicator"></span>
        </button>
        <p class="transit-near-me-error hidden-xs-up">error</p>
      `);
    });

    it('hides the loading indicator', () => {
      assert.isFalse($('.loading-indicator').hasClass('hidden-xs-up'));
      locationError($, $('button'))({code: ''});
      assert.isTrue($('.loading-indicator').hasClass('hidden-xs-up'));
    });

    it('shows an error message on timeout or geolocation failure', () => {
      locationError($, $('button'))({code: 'timeout', TIMEOUT: 'timeout'});
      assert.isFalse($('.transit-near-me-error').hasClass('hidden-xs-up'));
    });
  });
});
