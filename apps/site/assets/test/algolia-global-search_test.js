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
    window.jQuery = jsdom.rerequire("jquery");
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

  describe("getParams", function() {
    beforeEach(function() {
      document.body.innerHTML = "";
      Object.keys(AlgoliaGlobalSearch.SELECTORS).forEach(key => {
        const elType = (key == "searchBar") ? "input" : "div"
        document.body.innerHTML += `<${elType} id="${AlgoliaGlobalSearch.SELECTORS[key]}"></${elType}>`;
      });
      this.globalSearch = new AlgoliaGlobalSearch();
      this.globalSearch.init();
    });

    it("returns an object with from, query, and facet params", function() {
      const params = this.globalSearch.getParams();
      expect(params).to.be.an("object");
      expect(params).to.have.keys(["from", "query", "facets"]);
      expect(params.from).to.equal("global-search");
      expect(params.query).to.equal("");
      expect(params.facets).to.equal("");
    });

    it("query is the value in the search input", function() {
      window.jQuery(`#${AlgoliaGlobalSearch.SELECTORS.searchBar}`).val("new value");
      const params = this.globalSearch.getParams();
      expect(params.query).to.equal("new value");
    });
  });
});
