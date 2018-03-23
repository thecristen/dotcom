import { expect } from "chai";
import jsdom from "mocha-jsdom";
import { Algolia } from "../../assets/js/algolia-search";
import { AlgoliaGlobalSearch } from "../../assets/js/algolia-global-search";

describe("AlgoliaGlobalSearch", function() {
  jsdom({
    scripts: [
      'https://maps.googleapis.com/maps/api/js?libraries=places,geometry',
    ],
  });

  beforeEach(function() {
    window.algoliaConfig = {
      app_id: process.env.ALGOLIA_APP_ID,
      search: process.env.ALGOLIA_SEARCH_KEY,
      places: {
        app_id: process.env.ALGOLIA_PLACES_APP_ID,
        search: process.env.ALGOLIA_PLACES_SEARCH_KEY
      }
    }
  });

  it("constructor does not create a new Algolia instance", function() {
    const globalSearch = new AlgoliaGlobalSearch()
    expect(globalSearch.controller).to.equal(null);
  });

  describe("init", function() {
    it("generates a new Algolia client if search element exists", function() {
      document.body.innerHTML = "";
      Object.keys(AlgoliaGlobalSearch.SELECTORS).forEach(key => {
        document.body.innerHTML += `<div id="${AlgoliaGlobalSearch.SELECTORS[key]}"></div>`;
      });
      const globalSearch = new AlgoliaGlobalSearch();
      expect(document.getElementById(AlgoliaGlobalSearch.SELECTORS.searchBar)).to.be.an.instanceOf(window.HTMLDivElement);
      globalSearch.init();
      expect(globalSearch.controller).to.be.an.instanceOf(Algolia);
    });

    it("does not generates a new Algolia client if search element does not exist", function() {
      document.body.innerHTML = "";
      const globalSearch = new AlgoliaGlobalSearch();
      expect(document.getElementById(AlgoliaGlobalSearch.SELECTORS.searchBar)).to.equal(null);
      globalSearch.init();
      expect(globalSearch.controller).to.equal(null);
    });
  });
});
