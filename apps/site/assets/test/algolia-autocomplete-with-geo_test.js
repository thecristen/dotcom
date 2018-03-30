import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import { AlgoliaAutocompleteWithGeo } from "../../assets/js/algolia-autocomplete-with-geo";
import * as GoogleMapsHelpers from "../../assets/js/google-maps-helpers";

describe("AlgoliaAutocompleteWithGeo", function() {
  jsdom();
  const selectors = {
    input: "autocomplete-input",
    locationLoadingIndicator: "loading-indicator"
  };
  const indices = ["stops"];

  beforeEach(function() {
    document.body.innerHTML = `
      <input id="autocomplete-input" type="text" />
      <div id="loading-indicator"></div>
    `;
    window.autocomplete = jsdom.rerequire("autocomplete.js");
    this.parent = {
      changeLocationHeader: sinon.spy(),
      onLocationResults: sinon.spy((results) => results)
    };
    this.client = {
      resetSearch: sinon.spy(),
      updateParamsByKey: sinon.spy(),
    };
    this.ac = new AlgoliaAutocompleteWithGeo(selectors, indices, this.parent);
  });

  describe("constructor", function() {
    it("adds usemylocation and locations to indices", function() {
      expect(this.ac._indices).to.have.members(["stops", "usemylocation", "locations"]);
      expect(this.ac._loadingIndicator).to.be.an.instanceOf(window.HTMLDivElement);
      expect(this.ac._parent).to.equal(this.parent);
    });
  });

  describe("_datasetSource", function() {
    it("returns an empty search for usemylocation", function() {
      this.ac.init(this.client);
      const source = this.ac._datasetSource("usemylocation");
      const callback = sinon.spy();
      source("query value", callback);
      expect(callback.called).to.be.true;
      expect(callback.args[0][0]).to.be.an("array");
      expect(callback.args[0][0]).to.have.a.lengthOf(1);
      expect(callback.args[0][0][0]).to.have.keys(["data"]);
      expect(callback.args[0][0][0].data).to.equal("");
    });

    it("returns a callback that calls google for \"location\" index", function(done) {
      this.ac.init(this.client);
      sinon.stub(GoogleMapsHelpers, "autocomplete").resolves({
        locations: {
          hits: [{
            hitTitle: "location result"
          }]
        }
      });
      const source = this.ac._datasetSource("locations");
      const callback = sinon.spy();
      const result = source("location query", callback);
      Promise.resolve(result).then(() => {
        expect(GoogleMapsHelpers.autocomplete.called).to.be.true;
        expect(callback.called).to.be.true;
        GoogleMapsHelpers.autocomplete.restore()
        done();
      });
    });
  });

  describe("onHitSelected", function() {
    it("does a location search when index is \"locations\"", function(done) {
      const locationSearchResults = {
        locations: {hits: [{hitTitle: "location result"}]}
      }
      this.client.search = sinon.stub().resolves(locationSearchResults)
      this.ac.init(this.client);
      sinon.stub(GoogleMapsHelpers, "lookupPlace").resolves({
        geometry: {
          location: {
            lat: () => 42.0,
            lng: () => -72.0
          }
        },
        formatted_address: "10 Park Plaza, Boston, MA"
      });
      sinon.spy(this.ac, "_showLocation");
      sinon.spy(this.ac, "_searchAlgoliaByGeo");
      const result = this.ac.onHitSelected({
        _args: [{ id: "hitId" }, "locations"]
      });
      Promise.resolve(result).then(() => {
        expect(this.ac._showLocation.called).to.be.true;
        expect(this.ac._showLocation.args[0][2]).to.equal("10 Park Plaza, Boston, MA");
        expect(GoogleMapsHelpers.lookupPlace.called).to.be.true;
        Promise.resolve(this.ac._showLocation.getCall(0).returnValue).then((results) => {
          expect(results).to.equal(locationSearchResults);
          done();
        });
      });
    });
  });
});
