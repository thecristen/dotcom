import { expect } from "chai";
import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { AlgoliaAutocomplete } from "../../assets/js/algolia-autocomplete";
import { Algolia } from "../../assets/js/algolia-search";

describe("AlgoliaAutocomplete", () => {
  jsdom();
  const selectors = {
    input: "autocomplete-input"
  };
  const indices = ["stops"];
  const queries = {
    stops: {
      indexName: "stops",
      query: ""
    }
  };
  const queryParams = {
    stops: {
      hitsPerPage: 5,
      facets: ["*"],
      facetFilters: [[]]
    }
  };

  beforeEach(() => {
    window.algoliaConfig = {
      app_id: process.env.ALGOLIA_APP_ID,
      search: process.env.ALGOLIA_SEARCH_KEY,
      places: {
        app_id: process.env.ALGOLIA_PLACES_APP_ID,
        search: process.env.ALGOLIA_PLACES_SEARCH_KEY
      }
    }
    document.body.innerHTML = `
      <input id="autocomplete-input"></input>
    `;
    window.autocomplete = jsdom.rerequire("autocomplete.js");
  });
  it("constructor does not initialize autocomplete", () => {
    const ac = new AlgoliaAutocomplete(selectors, indices);
    expect(ac._selectors.container).to.equal(selectors.input + "-autocomplete-container");
    expect(ac._indices).to.equal(indices);
    expect(ac._autocomplete).to.equal(null);
  });

  describe("init", () => {
    it("initializes autocomplete if input exists", () => {
      expect(document.getElementById(selectors.input)).to.be.an.instanceOf(window.HTMLInputElement);
      const ac = new AlgoliaAutocomplete(selectors, indices);
      const client = new Algolia(queries, queryParams);
      ac.init(client);
      expect(ac._autocomplete).to.be.an("object");
      expect(ac._autocomplete.autocomplete).to.be.an("object");
    });
  });

  describe("_onResults", () => {
    it("only returns the hits for the given index", () => {
      const ac = new AlgoliaAutocomplete(selectors, indices);
      const callback = sinon.spy();
      const results = {
        stops: {
          hits: ["success"]
        },
        otherIndex: {
          hits: ["fail1", "fail2", "fail3"]
        }
      };
      expect(callback.called).to.be.false;
      ac._onResults(callback, "stops", results)
      expect(callback.called).to.be.true;
      expect(callback.args[0][0]).to.eql(["success"]);
    });
  });
});
