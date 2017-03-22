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
      $('body').append('<div id="test"><h2 id="transit-input"></h2><input id="client-width" /></div>');
    });

    afterEach(() => {
      $('#test').remove();
    });

    it("sets the clients width from the transit-input header", () => {
      const clientWidth = 840;
      $('#transit-input').width(clientWidth);
      setClientWidth($);
      assert.equal($('#client-width').val(), clientWidth);
    });
  });

  describe('getUrlParamter', () => {
    it("extracts parameters from URL", () => {
      const query_str = "?number=5&location[place]=mbta";
      assert.equal(getUrlParameter("number", query_str), "5");
      assert.equal(getUrlParameter("location[place]", query_str), "mbta");
    });

    it("Returns undefined when parameter is not available", () => {
      const query_str = "?number=5&location[place]=mbta";
      assert.equal(getUrlParameter("name", query_str), undefined);
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
      var reloaded = false;
      const loc = {
        search: "?number=5&location[address]=Boston%2C%20MA",
        reload: () => reloaded = true // test reload is called
      };
      assert.isFalse(validateTNMForm("event", loc, $));
      assert.isTrue(reloaded);
    });

    it("Will submit form if place has changed", () => {
      var reloaded = false
      const loc = {
        search: "?number=5&location[address]=Kendall",
        reload: () => reloaded = true
      };
      assert.isTrue(validateTNMForm("event", loc, $));
      assert.isFalse(reloaded);
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
      const fake_place = {
        geometry: {
          location: {
            lat: () => 8,
            lng: () => 5
          }
        }
      };
      const expected = "about://blank?latitude=8&longitude=5&location[client_width]=0&location[address]=Boston#transit-input"
      assert.equal(expected, constructUrl(fake_place, $));
    });

    it("Builds URL with place name when place has no geometry", () => {
      const named_place = {name: "Park"}
      const expected = "about://blank?location[address]=Park&location[client_width]=0#transit-input";
      assert.equal(expected, constructUrl(named_place, $));
    });
  });
});
