import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import { AlgoliaAutocompleteWithGeo } from "../../assets/js/algolia-autocomplete-with-geo";
import * as GoogleMapsHelpers from "../../assets/js/google-maps-helpers";

describe("AlgoliaAutocompleteWithGeo", function() {
  var $;
  jsdom();
  const selectors = {
    input: "autocomplete-input",
    container: "autocomplete-container",
    locationLoadingIndicator: "loading-indicator",
    resetButton: "reset-button"
  };
  const indices = ["stops", "routes"];

  beforeEach(function() {
    document.body.innerHTML = `
      <div id="powered-by-google-logo"></div>
      <div id="${selectors.container}">
        <input id="${selectors.input}" type="text" />
        <div id="${selectors.resetButton}"></div>
      </div>
      <div id="${selectors.locationLoadingIndicator}"></div>
    `;
    window.autocomplete = jsdom.rerequire("autocomplete.js");
    window.jQuery = jsdom.rerequire("jquery");
    $ = window.jQuery;
    this.parent = {
      changeLocationHeader: sinon.spy(),
      onLocationResults: sinon.spy((results) => results)
    };
    this.client = {
      reset: sinon.spy(),
      updateParamsByKey: sinon.spy(),
    };
    const headers = {
      stops: "Stops Header",
      locations: "Locations Header"
    };

    const locationsData = {
      position: 1,
      hitLimit: 3,
    };
    this.ac = new AlgoliaAutocompleteWithGeo(selectors, indices, headers, locationsData, this.parent);
    this.ac.init(this.client);
    $("#use-my-location-container").css("display", "none");
  });

  afterEach(function() {
    $("#use-my-location-container").css("display", "none");
  });

  describe("constructor", function() {
    it("adds locations to indices at the proper position", function() {
      expect(this.ac._indices).to.have.members(["stops", "locations", "routes"]);
      expect(this.ac._indices[1]).to.equal("locations");
      expect(this.ac._loadingIndicator).to.be.an.instanceOf(window.HTMLDivElement);
      expect(this.ac._parent).to.equal(this.parent);
    });
  });

  describe("init", function() {
    it("creates the use my location div and hides it", function() {
      expect($("#use-my-location-container").css("display")).to.equal("none");
    });
  });

  describe("focus/change behavior", function() {
    it("shows use my locations on focus", function() {
      expect($("#use-my-location-container").css("display")).to.equal("none");
      this.ac.onInputFocused();
      expect($("#use-my-location-container").css("display")).to.equal("block");
    });

    it("hides use my locations when the input is not empty", function() {
      $("#use-my-location-container").css("display", "block");
      $(`#${selectors.input}`).val("query");
      this.ac.onInputFocused();
      expect($("#use-my-location-container").css("display")).to.equal("none");
    });
  });

  describe("_datasetSource", function() {
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

  describe("location searches", function() {
    beforeEach(function() {
      this.locationSearchResults = {
        locations: {hits: [{hitTitle: "location result"}]}
      }
      this.client.search = sinon.stub().resolves(this.locationSearchResults)
      sinon.spy(this.ac, "showLocation");
      sinon.spy(this.ac, "_searchAlgoliaByGeo");
      sinon.stub(GoogleMapsHelpers, "lookupPlace").resolves({
        geometry: {
          location: {
            lat: () => 42.0,
            lng: () => -72.0
          }
        },
        formatted_address: "10 Park Plaza, Boston, MA"
      });
    });

    afterEach(function() {
      GoogleMapsHelpers.lookupPlace.restore();
    });

    describe("onHitSelected", function() {
      it("does a location search when index is \"locations\"", function(done) {
        this.ac.init(this.client);
        const result = this.ac.onHitSelected({
          originalEvent: {_args: [{ id: "hitId", description: "10 Park Plaza, Boston, MA" }, "locations"]}
        });
        Promise.resolve(result).then(() => {
          expect(this.ac.showLocation.called).to.be.true;
          expect(this.ac.showLocation.args[0][2]).to.equal("10 Park Plaza, Boston, MA");
          expect($(`#${selectors.input}`).val()).to.equal("10 Park Plaza, Boston, MA");
          expect(GoogleMapsHelpers.lookupPlace.called).to.be.true;
          Promise.resolve(this.ac.showLocation.getCall(0).returnValue).then((results) => {
            expect(results).to.equal(this.locationSearchResults);
            done();
          });
        });
      });
    });

    describe("clickHighlightedOrFirstResult", function() {
      it("visits the highlightedHit url", function(done) {
        this.ac.init(this.client);
        this.ac._highlightedHit = {
          index: "locations",
          hit: {
            id: "highlightedHitId",
            url: "/success"
          }
        };
        const result = this.ac.clickHighlightedOrFirstResult();
        Promise.resolve(result).then(() => {
          expect(this.ac.showLocation.called).to.be.true;
          expect(this.ac.showLocation.args[0][2]).to.equal("10 Park Plaza, Boston, MA");
          expect(GoogleMapsHelpers.lookupPlace.called).to.be.true;
          Promise.resolve(this.ac.showLocation.getCall(0).returnValue).then((results) => {
            expect(results).to.equal(this.locationSearchResults);
            done();
          });
        });
      });
    });
  });
});
