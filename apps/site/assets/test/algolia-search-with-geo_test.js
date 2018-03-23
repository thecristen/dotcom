import { expect, assert } from "chai";
import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { AlgoliaWithGeo } from "../../assets/js/algolia-search-with-geo";

describe("AlgoliaWithGeo", function() {
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

    this.algoliaWithGeo = new AlgoliaWithGeo({
      stops: {
        indexName: "stops"
      }
    }, {stops: {foo: "bar"}});
  });

  describe("AlgoliaWithGeo._doSearch", function() {
    it("searches both indexes and updates widgets when both have returned", function(done) {
      this.algoliaWithGeo.updateWidgets = function(results) {
        assert.deepEqual(results, {
          index: "foo",
          locations: "loc"
        });
        done();
      };
      sinon.stub(this.algoliaWithGeo, "_processAlgoliaResults").returnsArg(0);
      sinon.stub(this.algoliaWithGeo._client, "search").resolves({ index: "foo" } );
      sinon.stub(this.algoliaWithGeo, "_doGoogleAutocomplete").resolves({ locations: "loc" });
      this.algoliaWithGeo.search("query");
    });
  });
});
