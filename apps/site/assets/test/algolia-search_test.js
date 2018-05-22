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
      search: sinon.stub().resolves([])
    }
    this.widget = {
      init: sinon.spy(),
      render: sinon.spy()
    }
    this.algolia = new Algolia({
      stops: {
        indexName: "stops",
      }
    }, {stops: {foo: "bar", hitsPerPage: 5}});
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
      const algolia = new Algolia({stops: {indexName:"stops"}}, {stops: {foo: "bar"}});
      expect(algolia._client).to.equal(null);
      console.error.restore()
    });
  });

  describe("Algolia.reset", function() {
    it("resets search params regardless of active queries", function() {
      this.algolia._queries["stops"].params = { not_default: "nope" };
      this.algolia._activeQueryIds = [];
      this.algolia.reset();
      expect(this.algolia._queries).to.have.keys(["stops"]);
      expect(this.algolia._queries.stops).to.be.an("object");
      expect(this.algolia._queries.stops).to.have.keys(["indexName", "params"]);
      expect(this.algolia._queries.stops.params).to.have.keys(["foo", "hitsPerPage"]);
    });
  });

  describe("Algolia._buildAllQueries", function() {
    it("builds a list of queries for result list AND facets", function() {
      expect(this.algolia._queries).to.be.an("object");
      expect(this.algolia._queries).to.have.keys(["stops"]);
      const queries = this.algolia._buildAllQueries({});
      expect(queries).to.be.an("array");
      expect(queries).to.have.a.lengthOf(2);

      expect(queries[0]).to.have.all.keys(["indexName", "params", "query"]);
      expect(queries[0].indexName).to.equal("stops");
      expect(queries[0].params).to.have.all.keys(["foo", "hitsPerPage"]);

      expect(queries[1]).to.have.all.keys(["indexName", "params", "query"]);
      expect(queries[1].indexName).to.equal("stops");
      expect(queries[1].params).to.have.all.keys(["facets", "hitsPerPage"]);
      expect(queries[1].params.facets).to.include("*");
    });
  });

  describe("Algolia.search", function() {
    it("performs a search", function() {
      this.algolia._client = this.mockClient;
      this.algolia._doSearch = sinon.spy();
      this.algolia.search({query: "query"});
      expect(this.algolia._doSearch.called).to.be.true;
      expect(this.algolia._doSearch.args[0][0][0]).to.have.keys(["indexName", "params", "query"]);
      expect(this.algolia._doSearch.args[0][0][0].indexName).to.equal("stops");
      expect(this.algolia._doSearch.args[0][0][0].params).to.have.keys(["foo", "hitsPerPage"]);
      expect(this.algolia._doSearch.args[0][0][1]).to.have.keys(["indexName", "params", "query"]);
      expect(this.algolia._doSearch.args[0][0][1].params).to.have.keys(["facets", "hitsPerPage"]);
      expect(this.algolia._doSearch.args[0][0][1].params.facets).to.include("*");
    });

    it("returns a promise", function() {
      this.algolia._client = this.mockClient;
      sinon.stub(this.algolia, "_processAlgoliaResults").resolves({});
      const returned = this.algolia.search({query: "query"});
      expect(returned).to.be.an.instanceOf(Promise)
    });

    it("updates the search query if search is called with arguments", function() {
      this.algolia._client = this.mockClient;
      this.algolia._doSearch = sinon.spy();
      this.algolia.search({query: "search string"});
      expect(this.algolia._doSearch.args[0][0][0]["query"]).to.equal("search string");
    });

    it("uses a previous query if search is called with no arguments", function() {
      this.algolia._client = this.mockClient;
      this.algolia._doSearch = sinon.spy();
      this.algolia.search({query: "previous query"});
      this.algolia.search();
      expect(this.algolia._doSearch.args[0][0][0]["query"]).to.equal("previous query");
    });

    it("returns empty if search is called with blank query", function() {
      this.algolia._client = this.mockClient;
      this.algolia._doSearch = sinon.spy();
      this.algolia.updateWidgets = sinon.spy();
      this.algolia.search({query: ""});
      const returned = this.algolia.search();
      expect(this.algolia.updateWidgets.calledWith({}));
    });
  });

  describe("Algolia._processAlgoliaResults", function() {
    it("returns results in a promise", function(done) {
      this.algolia._client = this.mockClient;
      this.algolia.addWidget(this.widget);
      const response = {
        results: [{
          index: "stops"
        }]
      };
      const results = this.algolia._processAlgoliaResults()(response);
      results.then((result) => {
        this.algolia.updateWidgets(result);
        expect(this.widget.render.called).to.be.true;
        expect(this.widget.render.args[0]).to.be.an("array");
        expect(this.widget.render.args[0]).to.have.lengthOf(1);
        expect(this.widget.render.args[0][0]).to.have.keys(["stops"]);
        expect(this.widget.render.args[0][0].stops).to.have.keys(["index"]);
        expect(this.widget.render.args[0][0].stops.index).to.equal("stops");
        done();
      });
    });
  });

  describe("addPage", function() {
    it("increments the hit count for a group", function() {
      this.algolia._client = this.mockClient;
      this.algolia._doSearch = sinon.spy();

      this.algolia.search({query: "query"});
      expect(this.algolia._doSearch.args[0][0][0].params.hitsPerPage).to.equal(5);

      this.algolia.addPage("stops");
      expect(this.algolia._queries.stops.params.hitsPerPage)
    });
  });
});
