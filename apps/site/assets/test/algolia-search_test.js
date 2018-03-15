import { expect } from "chai";
import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { Algolia } from "../../assets/js/algolia-search";

describe("Algolia", function() {
  jsdom();

  beforeEach(function() {
    window.algoliaConfig = {
      app_id: process.env.ALGOLIA_APP_ID,
      search: process.env.ALGOLIA_SEARCH_KEY,
      places: {
        app_id: process.env.ALGOLIA_PLACES_APP_ID,
        search: process.env.ALGOLIA_PLACES_SEARCH_KEY
      }
    }
    this.mockClient = {
      search: sinon.spy()
    }
    this.widget = {
      init: sinon.spy(),
      render: sinon.spy()
    }
    this.algolia = new Algolia(["stops"], {foo: "bar"});
  });

  describe("constructor", function() {
    it("builds an Algolia object", function() {
      expect(window.algoliaConfig.app_id).to.be.a("string");
      expect(window.algoliaConfig.search).to.be.a("string");
      expect(this.algolia._config).to.eq(window.algoliaConfig);
      expect(this.algolia._client.applicationID).to.equal(window.algoliaConfig.app_id);
    });

    it("does not initalize client if config is invalid", function() {
      window.algoliaConfig = {
        app_id: null
      }
      sinon.stub(console, "error")
      const algolia = new Algolia(["stops"], {foo: "bar"})
      expect(algolia._client).to.equal(null);
      console.error.restore()
    });
  });

  describe("Algolia.resetSearch", function() {
    it("resets search params", function() {
      this.algolia.resetSearch();
      expect(this.algolia._params).to.have.keys(["stops"]);
      expect(this.algolia._params.stops).to.be.an("object");
      expect(this.algolia._params.stops).to.have.keys(["foo"]);
    });
  });

  describe("Algolia._buildAllQueries", function() {
    it("builds a list of queries for result list AND facets", function() {
      expect(this.algolia._indices).to.be.an("array");
      expect(this.algolia._indices).to.have.members(["stops"]);
      const queries = this.algolia._buildAllQueries();
      expect(queries).to.be.an("array");
      expect(queries).to.have.a.lengthOf(2);

      expect(queries[0]).to.have.all.keys(["indexName", "params", "query"]);
      expect(queries[0].indexName).to.equal("stops");
      expect(queries[0].params).to.have.all.keys(["foo"]);

      expect(queries[1]).to.have.all.keys(["indexName", "params", "query"]);
      expect(queries[1].indexName).to.equal("stops");
      expect(queries[1].params).to.have.all.keys(["facets", "hitsPerPage"]);
      expect(queries[1].params.facets).to.include("*");
    });
  });

  describe("Algolia.search", function() {
    it("performs a search", function() {
      this.algolia._client = this.mockClient;
      this.algolia.search("query");
      expect(this.mockClient.search.called).to.be.true;
      expect(this.mockClient.search.args[0][0][0]).to.have.keys(["indexName", "params", "query"]);
      expect(this.mockClient.search.args[0][0][0].indexName).to.equal("stops");
      expect(this.mockClient.search.args[0][0][0].params).to.have.keys(["foo"]);
      expect(this.mockClient.search.args[0][0][1]).to.have.keys(["indexName", "params", "query"]);
      expect(this.mockClient.search.args[0][0][1].params).to.have.keys(["facets", "hitsPerPage"]);
      expect(this.mockClient.search.args[0][0][1].params.facets).to.include("*");
    });

    it("updates the search query if search is called with arguments", function() {
      this.algolia._client = this.mockClient;
      this.algolia.search("search string");
      expect(this.mockClient.search.args[0][0][0]["query"]).to.equal("search string");
    });

    it("uses a previous query if search is called with no arguments", function() {
      this.algolia._client = this.mockClient;
      this.algolia.search("previous query");
      this.algolia.search();
      expect(this.mockClient.search.args[0][0][0]["query"]).to.equal("previous query");
    });
  });

  describe("Algolia.onResults", function() {
    it("sends results to widgets", function() {
      this.algolia._client = this.mockClient;
      this.algolia.addWidget(this.widget);
      const response = {
        results: [{
          index: "stops"
        }]
      };
      this.algolia.onResults(null, response);
      expect(this.widget.render.called).to.be.true
      expect(this.widget.render.args[0]).to.be.an("array");
      expect(this.widget.render.args[0]).to.have.lengthOf(1);
      expect(this.widget.render.args[0][0]).to.have.keys(["stops"]);
      expect(this.widget.render.args[0][0].stops).to.have.keys(["index"]);
      expect(this.widget.render.args[0][0].stops.index).to.equal("stops");
    });
  });
});
