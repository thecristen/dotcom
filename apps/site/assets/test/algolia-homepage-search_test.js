import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import { Algolia } from "../../assets/js/algolia-search";
import { AlgoliaHomepageSearch } from "../../assets/js/algolia-homepage-search";
import { AlgoliaAutocomplete } from "../../assets/js/algolia-autocomplete";

describe("AlgoliaHomepageSearch", function() {
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
  });

  describe("constructor", () => {
    it("initializes autocomplete if input exists", () => {
      document.body.innerHTML = `
        <div id="powered-by-google-logo"></div>
        <input id="${AlgoliaHomepageSearch.SELECTORS.input}"></input>
        <i id="${AlgoliaHomepageSearch.SELECTORS.resetButton}"></i>
        <div id="${AlgoliaHomepageSearch.SELECTORS.locationResultsBody}"></div>
        <div id="${AlgoliaHomepageSearch.SELECTORS.locationResultsHeader}"></div>
      `;
      const ac = new AlgoliaHomepageSearch();
      expect(ac._input).to.be.an.instanceOf(window.HTMLInputElement);
      expect(ac._controller).to.be.an.instanceOf(Algolia);
      expect(ac._autocomplete).to.be.an.instanceOf(AlgoliaAutocomplete);
      expect(ac._controller.widgets).to.include(ac._autocomplete);
    });

    it("does not initialize autocomplete if input does not exist", () => {
      document.body.innerHTML = `
        <input id="stop-search-fail"></input>
      `;
      const ac = new AlgoliaHomepageSearch();
      expect(ac._input).to.equal(null);
      expect(ac._controller).to.equal(null);
      expect(ac._autocomplete).to.equal(null);
    });
  });

  describe("_showLocation", () => {
    it("adds query parameters for analytics", () => {
      document.body.innerHTML = `
        <div id="powered-by-google-logo"></div>
        <input id="${AlgoliaHomepageSearch.SELECTORS.input}"></input>
        <i id="${AlgoliaHomepageSearch.SELECTORS.resetButton}"></i>
        <div id="${AlgoliaHomepageSearch.SELECTORS.locationResultsBody}"></div>
        <div id="${AlgoliaHomepageSearch.SELECTORS.locationResultsHeader}"></div>
      `;
      const ac = new AlgoliaHomepageSearch();
      window.Turbolinks = {
        visit: sinon.spy()
      };
      window.encodeURIComponent = (str) => str.replace(/\s/g, "+");
      ac._autocomplete.showLocation("42.0", "-71.0", "10 Park Plaza, Boston, MA");
      expect(window.Turbolinks.visit.called).to.be.true;
      expect(window.Turbolinks.visit.args[0][0]).to.contain("from=homepage-search");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("latitude=42.0");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("longitude=-71.0");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("address=10+Park+Plaza,+Boston,+MA");
    });
  });
});
