import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { setClientWidth, getUrlParameter, validateTNMForm, constructUrl } from '../../web/static/js/transit-near-me';

describe('transt-near-me', () => {
  var $;
  jsdom();

  beforeEach(() => {
    $ = jsdom.rerequire('jquery');
  });

  describe('setClientWidth', () => {
    beforeEach(() => {
      $('body').append('<div id="test"><h2 id="transit-input"></h2><input id="client-width /"></div>');
    });

    afterEach(() => {
      $('#test').remove();
    });

    it("sets the clients width from the transit-input header", () => {
      var clientWidth = 840;
      $('#transit-input').width(clientWidth);
      setClientWidth($);
      assert.equal($('#transit-input').width(), clientWidth);
    });
  });

  describe('getUrlParamter', () => {
    it("extracts parameters from URL", () => {
      // Fake url params
      Object.defineProperty(window.location, 'search', {
          writable: true,
          value: "?number=5&location[place]=mbta"
      });

      assert.equal(getUrlParameter("number"), "5");
      assert.equal(getUrlParameter("location[place]"), "mbta");
    });

    it("Returns undefined when parameter is not available", () => {
      // Fake url params
      Object.defineProperty(window.location, 'search', {
          writable: true,
          value: "?number=5"
      });
      assert.equal(getUrlParameter("name"), undefined);
    });
  });

  describe('validateTNMForm', () => {
    beforeEach(() => {
      $('body').append(`
        <div class="transit-near-me">
          <form>
            <input name="location[address]" value="Boston, MA" />
          </form>
        </div>
      `);
    });

    afterEach(() => {
      $('.transit-near-me').remove();
    });

    it("Does not resubmit the form when location has not changed", () => {
      Object.defineProperty(window.location, 'search', {
          writable: true,
          value: "?number=5&location[address]=Boston%2C%20MA"
      });
      assert.isFalse(validateTNMForm("event", $));
    });

    it("Will submit form if place has changed", () => {
      Object.defineProperty(window.location, 'search', {
          writable: true,
          value: "?number=5&location[address]=Kendall"
      });
      assert.isTrue(validateTNMForm("event", $));
    });
  });

  describe('constructUrl', () => {
    beforeEach(() => {
      $('body').append(`
        <div class="transit-near-me">
          <form>
            <input name="location[address]" value="Boston" />
          </form>
        </div>
      `);
    });

    afterEach(() => {
      $('.transit-near-me').remove();
    });

    it("Builds URL with lat/lng when place has geometry", () => {
      var fake_place = {geometry: {location: {}}};
      fake_place.geometry.location.lat = function () {return 8};
      fake_place.geometry.location.lng = function () {return 5};
      var expected = "about://blank?latitude=8&longitude=5&location[client_width]=0&location[address]=Boston#transit-input"
      assert.equal(expected, constructUrl(fake_place, $));
    });

    it("Builds URL with place name when place has no geometry", () => {
      var fake_place = {name: "Park"}
      var expected = "about://blank?location[address]=Park&location[client_width]=0#transit-input";
      assert.equal(expected, constructUrl(fake_place, $));
    });
  });
});
