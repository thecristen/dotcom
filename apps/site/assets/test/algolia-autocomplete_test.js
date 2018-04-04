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
    window.Turbolinks = {
      visit: sinon.spy()
    }
  });
  it("constructor does not initialize autocomplete", () => {
    const ac = new AlgoliaAutocomplete(selectors, indices);
    expect(ac._selectors.resultsContainer).to.equal(selectors.input + "-autocomplete-results");
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

  describe("onCursorChanged", () => {
    it("sets this._highlightedHit", () => {
      const ac = new AlgoliaAutocomplete(selectors, indices);
      ac.init({});
      expect(ac._highlightedHit).to.equal(null);
      const hit = {
        url: "/success"
      }
      ac.onCursorChanged({_args: [hit, indices[0]]});
      expect(ac._highlightedHit.hit).to.equal(hit);
      expect(ac._highlightedHit.index).to.equal(indices[0]);
    });
  });

  describe("onCursorRemoved", () => {
    it("sets this._highlightedHit to null", () => {
      const ac = new AlgoliaAutocomplete(selectors, indices);
      ac.init({});
      ac._highlightedHit = {
        index: indices[0],
        hit: {
          url: "success"
        }
      };
      ac.onCursorRemoved({});
      expect(ac._highlightedHit).to.equal(null);
    });
  });

  describe("clickFirstResult", () => {
    describe("when results exist:", () => {
      it("clicks the first result of the first index with hits", () => {
        const ac = new AlgoliaAutocomplete(selectors, ["stops", "locations"]);
        ac.init({});
        ac._results = {
          stops: {
            hits: [{
              url: "/stops"
            }]
          },
          locations: {
            hits: [{
              url: "/locations"
            }]
          }
        };
        expect(window.Turbolinks.visit.called).to.be.false;
        ac.clickFirstResult();
        expect(window.Turbolinks.visit.called).to.be.true;
        expect(window.Turbolinks.visit.args[0][0]).to.equal("/stops");
      });

      it("finds the first index with results if some are empty", () => {
        const ac = new AlgoliaAutocomplete(selectors, ["stops", "locations"]);
        ac.init({});
        ac._results = {
          stops: {
            hits: []
          },
          locations: {
            hits: [{
              url: "/locations"
            }]
          }
        };
        expect(window.Turbolinks.visit.called).to.be.false;
        ac.clickFirstResult();
        expect(window.Turbolinks.visit.called).to.be.true;
        expect(window.Turbolinks.visit.args[0][0]).to.equal("/locations");
      });

      it("does nothing if results list is empty", () => {
        const ac = new AlgoliaAutocomplete(selectors, ["stops", "locations"]);
        ac.init({});
        ac._results = {
          stops: {
            hits: []
          },
          locations: {
            hits: []
          }
        };
        expect(window.Turbolinks.visit.called).to.be.false;
        ac.clickFirstResult();
        expect(window.Turbolinks.visit.called).to.be.false;
      });
    });

    describe("when results do not exist", () => {
      it("does nothing", () => {
        const ac = new AlgoliaAutocomplete(selectors, ["stops", "locations"]);
        ac.init({});
        expect(Object.keys(ac._results)).to.have.members([]);
        expect(window.Turbolinks.visit.called).to.be.false;
        ac.clickFirstResult();
        expect(window.Turbolinks.visit.called).to.be.false;
      });
    });
  });

  describe("onClickGoBtn", () => {
    describe("when this._highlightedHit exists", () => {
      it("visits the highlightedHit url if higlightedHit is not null", () => {
        const ac = new AlgoliaAutocomplete(selectors, indices);
        ac.init({});
        ac._highlightedHit = {
          index: indices[0],
          hit: {
            url: "/success"
          }
        };
        expect(window.Turbolinks.visit.called).to.be.false;
        ac.onClickGoBtn({});
        expect(window.Turbolinks.visit.called).to.be.true;
        expect(window.Turbolinks.visit.args[0][0]).to.equal("/success");
      });
    });

    describe("when this._highlightedHit is null", () => {
      describe("and this._results has results", () => {
        it("visits the url of the first index's results", () => {
          const ac = new AlgoliaAutocomplete(selectors, ["stops", "locations"]);
          ac.init({});
          ac._results = {
            stops: {
              hits: [{
                url: "/success"
              }]
            },
            locations: {
              hits: [{
                url: "/fail"
              }]
            }
          };
          expect(ac._highlightedHit).to.equal(null);
          expect(window.Turbolinks.visit.called).to.be.false;
          ac.onClickGoBtn({});
          expect(window.Turbolinks.visit.called).to.be.true;
          expect(window.Turbolinks.visit.args[0][0]).to.equal("/success");
        });
      });
    });

    describe("and this._results has no results", () => {
      it("does nothing", () => {
        const ac = new AlgoliaAutocomplete(selectors, ["stops", "locations"]);
        ac.init({});
        expect(Object.keys(ac._results)).to.have.members([]);
        expect(ac._highlightedHit).to.equal(null);
        expect(window.Turbolinks.visit.called).to.be.false;
        ac.onClickGoBtn({});
        expect(window.Turbolinks.visit.called).to.be.false;
      });
    });
  });
});
