import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import { Algolia } from "../js/algolia-search";
import { AlgoliaStopSearch } from "../js/algolia-stop-search";
import { AlgoliaAutocomplete } from "../js/algolia-autocomplete";

describe("AlgoliaStopSearch", () => {
  jsdom();
  beforeEach(() => {
    window.jQuery = jsdom.rerequire("jquery");
    window.autocomplete = jsdom.rerequire("autocomplete.js");
    document.body.innerHTML = `
      <div id="powered-by-google-logo"></div>
      <input id="${AlgoliaStopSearch.SELECTORS.input}"></input>
      <div id="${AlgoliaStopSearch.SELECTORS.resetButton}"></div>
      <button id ="${AlgoliaStopSearch.SELECTORS.goBtn}"></button>
    `;
  });

  describe("constructor", () => {
    it("initializes autocomplete if input exists", () => {
      const ac = new AlgoliaStopSearch();
      expect(ac.input).to.be.an.instanceOf(window.HTMLInputElement);
      expect(ac.controller).to.be.an.instanceOf(Algolia);
      expect(ac.autocomplete).to.be.an.instanceOf(AlgoliaAutocomplete);
      expect(ac.controller.widgets).to.include(ac.autocomplete);
    });
    it("does not initialize autocomplete if input does not exist", () => {
      document.body.innerHTML = `
        <input id="stop-search-fail"></input>
      `;
      const ac = new AlgoliaStopSearch();
      expect(ac.input).to.equal(null);
      expect(ac.controller).to.equal(null);
      expect(ac.autocomplete).to.equal(null);
    });
  });

  describe("clicking Go button", () => {
    it("calls autocomplete.clickHighlightedOrFirstResult", () => {
      const search = new AlgoliaStopSearch();
      const $ = window.jQuery;

      const $goBtn = $(`#${AlgoliaStopSearch.SELECTORS.goBtn}`);
      expect($goBtn.length).to.equal(1);

      search.autocomplete.clickHighlightedOrFirstResult = sinon.spy();
      $goBtn.click();
      expect(search.autocomplete.clickHighlightedOrFirstResult.called).to.be.true;
    });
  });

  describe("showLocation", () => {
    it("adds query parameters for analytics", () => {
      const ac = new AlgoliaStopSearch();
      window.Turbolinks = {
        visit: sinon.spy()
      };
      window.encodeURIComponent = string => string.replace(/\s/g, "%20").replace(/\&/g, "%26");
      ac.autocomplete.showLocation("42.0", "-71.0", "10 Park Plaza, Boston, MA");
      expect(window.Turbolinks.visit.called).to.be.true;
      expect(window.Turbolinks.visit.args[0][0]).to.contain("from=stop-search");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("latitude=42.0");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("longitude=-71.0");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("address=10%20Park%20Plaza,%20Boston,%20MA");
    });
  });
});
