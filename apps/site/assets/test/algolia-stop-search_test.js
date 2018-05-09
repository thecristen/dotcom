import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import { Algolia } from "../../assets/js/algolia-search";
import { AlgoliaStopSearch } from "../../assets/js/algolia-stop-search";
import { AlgoliaAutocomplete } from "../../assets/js/algolia-autocomplete";

describe("AlgoliaStopSearch", function() {
  jsdom();
  const selector = "autocomplete-input";
  beforeEach(() => {
    window.algoliaConfig = {
      app_id: process.env.ALGOLIA_APP_ID,
      search: process.env.ALGOLIA_SEARCH_KEY,
      places: {
        app_id: process.env.ALGOLIA_PLACES_APP_ID,
        search: process.env.ALGOLIA_PLACES_SEARCH_KEY
      }
    }
    window.jQuery = jsdom.rerequire("jquery");
    window.autocomplete = jsdom.rerequire("autocomplete.js");
    document.body.innerHTML = `
      <div id="powered-by-google-logo"></div>
      <input id="${AlgoliaStopSearch.SELECTORS.input}"></input>
      <div id="${AlgoliaStopSearch.SELECTORS.locationResultsBody}"></div>
      <div id="${AlgoliaStopSearch.SELECTORS.locationResultsHeader}"></div>
    `;
  });

  describe("constructor", () => {
    it("initializes autocomplete if input exists", () => {
      const ac = new AlgoliaStopSearch();
      expect(ac._input).to.be.an.instanceOf(window.HTMLInputElement);
      expect(ac._controller).to.be.an.instanceOf(Algolia);
      expect(ac._autocomplete).to.be.an.instanceOf(AlgoliaAutocomplete);
      expect(ac._controller.widgets).to.include(ac._autocomplete);
    });
    it("does not initialize autocomplete if input does not exist", () => {
      document.body.innerHTML = `
        <input id="stop-search-fail"></input>
      `;
      const ac = new AlgoliaStopSearch();
      expect(ac._input).to.equal(null);
      expect(ac._controller).to.equal(null);
      expect(ac._autocomplete).to.equal(null);
    });
  });

  describe("clicking Go button", () => {
    it("calls autocomplete.clickHighlightedOrFirstResult", () => {
      const search = new AlgoliaStopSearch();
      const $ = window.jQuery;

      const $goBtn = $("#" + search._autocomplete._selectors.goBtn);
      expect($goBtn.length).to.equal(1);

      search._autocomplete.clickHighlightedOrFirstResult = sinon.spy();
      $goBtn.click();
      expect(search._autocomplete.clickHighlightedOrFirstResult.called).to.be.true;
    });
  });
});
