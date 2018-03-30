import jsdom from "mocha-jsdom";
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
    window.autocomplete = jsdom.rerequire("autocomplete.js");
  });

  describe("constructor", () => {
    it("initializes autocomplete if input exists", () => {
      document.body.innerHTML = `
        <input id="${AlgoliaStopSearch.SELECTORS.input}"></input>
        <div id="${AlgoliaStopSearch.SELECTORS.locationResultsBody}"></div>
        <div id="${AlgoliaStopSearch.SELECTORS.locationResultsHeader}"></div>
      `;
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
});
