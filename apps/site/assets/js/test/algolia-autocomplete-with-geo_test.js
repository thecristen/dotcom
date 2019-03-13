import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import AlgoliaAutocompleteWithGeo from "../algolia-autocomplete-with-geo";
import * as GoogleMapsHelpers from "../google-maps-helpers";
import google from "./google-stubs";

/* eslint-disable func-names */
/* eslint-disable prefer-arrow-callback */
/* eslint-disable no-unused-expressions */

describe("AlgoliaAutocompleteWithGeo", function() {
  let $;
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
      onLocationResults: sinon.spy(results => results)
    };
    this.client = {
      reset: sinon.spy(),
      updateParamsByKey: sinon.spy()
    };
    const locationParams = {
      position: 1,
      hitLimit: 3
    };
    this.popular = [
      {
        name: "test"
      }
    ];
    this.ac = new AlgoliaAutocompleteWithGeo({
      id: "id",
      popular: this.popular,
      parent: this.parent,
      selectors,
      indices,
      locationParams
    });
    sinon.stub(this.ac, "visit");
    this.ac.init(this.client);
  });

  describe("constructor", function() {
    it("adds locations to indices at the proper position", function() {
      expect(this.ac._indices).to.have.members([
        "stops",
        "locations",
        "routes",
        "usemylocation",
        "popular"
      ]);
      expect(this.ac._indices[1]).to.equal("locations");
      expect(this.ac._loadingIndicator).to.be.an.instanceOf(
        window.HTMLDivElement
      );
      expect(this.ac._parent).to.equal(this.parent);
    });
  });

  describe("_datasetSource", function() {
    it('returns a callback that calls google for "location" index', function(done) {
      this.ac.init(this.client);
      sinon.stub(GoogleMapsHelpers, "autocomplete").resolves({
        locations: {
          hits: [
            {
              hitTitle: "location result"
            }
          ]
        }
      });
      const source = this.ac._datasetSource("locations");
      const callback = sinon.spy();
      const result = source("location query", callback);
      Promise.resolve(result).then(() => {
        setTimeout(() => {
          expect(GoogleMapsHelpers.autocomplete.called).to.be.true;
          expect(callback.called).to.be.true;
          GoogleMapsHelpers.autocomplete.restore();
          done();
        }, this.ac.debounceInterval + 500);
      });
    });

    it("returns a callback that returns the popular array that was provided", function() {
      const source = this.ac._datasetSource("popular");
      const callback = sinon.spy();
      const result = source("popular", callback);
      expect(callback.called).to.be.true;
      expect(callback.args[0][0]).to.equal(this.popular);
    });

    it("returns a callback that returns a blank usemylocation result", function() {
      const source = this.ac._datasetSource("usemylocation");
      const callback = sinon.spy();
      const result = source("usemylocation", callback);
      expect(callback.called).to.be.true;
      expect(JSON.stringify(callback.args[0][0])).to.equal(
        JSON.stringify([{}])
      );
    });
  });

  describe("useMyLocationSearch", function() {
    it("redirects to Transit Near Me if geocode succeeds", function(done) {
      window.navigator.geolocation = {
        getCurrentPosition: (resolve, reject) => {
          resolve({ coords: { latitude: 42.0, longitude: -71.0 } });
        }
      };
      window.encodeURIComponent = str => str;
      sinon
        .stub(GoogleMapsHelpers, "reverseGeocode")
        .resolves("10 Park Plaza, Boston MA");
      const result = this.ac.useMyLocationSearch();
      Promise.resolve(result).then(() => {
        expect(this.ac.visit.called).to.be.true;
        expect(this.ac.visit.args[0][0]).to.equal(
          "about:///transit-near-me?latitude=42&longitude=-71&address=10%20Park%20Plaza,%20Boston%20MA"
        );
        done();
      });
    });
    it("resets search if geolocation fails", function(done) {
      window.navigator.geolocation = {
        getCurrentPosition: (resolve, reject) => {
          reject({ code: 1, message: "User denied Geolocation" });
        }
      };
      const result = this.ac.useMyLocationSearch();
      Promise.resolve(result).then(() => {
        expect(this.ac._input.value).to.equal("");
        expect(this.ac._input.disabled).to.be.false;
        done();
      });
    });
  });

  describe("location searches", function() {
    beforeEach(function() {
      this.locationSearchResults = {
        locations: { hits: [{ hitTitle: "location result" }] }
      };

      this.client.search = sinon.stub().resolves(this.locationSearchResults);

      window.google = google;

      sinon.spy(this.ac, "showLocation");

      this.autocompleteService = new window.google.maps.places.AutocompleteService();

      sinon
        .stub(this.autocompleteService, "getPlacePredictions")
        .callsFake((_input, callback) => {
          return callback(
            [
              {
                description: "10 Park Plaza, Boston, MA",
                place_id: "10_PARK_PLAZA"
              }
            ],
            window.google.maps.places.PlacesServiceStatus.OK
          );
        });

      this.geocoder = new window.google.maps.Geocoder();

      sinon.stub(this.geocoder, "geocode").callsFake((_input, callback) =>
        callback(
          [
            {
              geometry: {
                location: {
                  lat: () => 42.1,
                  lng: () => -72.0
                }
              },
              formatted_address: "10 Park Plaza, Boston, MA"
            }
          ],
          window.google.maps.GeocoderStatus.OK
        )
      );
    });

    describe("onHitSelected", function() {
      it('does a location search when index is "locations"', function(done) {
        window.encodeURIComponent = params => {
          const forceString = params.toString();
          return forceString.replace(/\s/g, "%20").replace(/\&/g, "%26");
        };
        this.ac.init(this.client);
        this.ac.onFocus(); // initialize session token
        this.ac.sessionToken.id = "SESSION_TOKEN";
        const result = this.ac.onHitSelected(
          {
            originalEvent: {
              _args: [
                { id: "hitId", description: "10 Park Plaza, Boston, MA" },
                "locations"
              ]
            }
          },
          this.geocoder
        );
        Promise.resolve(result).then(() => {
          expect(this.geocoder.geocode.called).to.be.true;

          const { placeId } = this.geocoder.geocode.args[0][0];
          expect(typeof placeId).to.equal("string");

          expect(this.ac.showLocation.called).to.be.true;
          expect($(`#${selectors.input}`).val()).to.equal(
            "10 Park Plaza, Boston, MA"
          );

          expect(this.ac.visit.called).to.be.true;
          expect(this.ac.visit.args[0][0]).to.contain("latitude=42.1");
          expect(this.ac.visit.args[0][0]).to.contain("longitude=-72");
          expect(this.ac.visit.args[0][0]).to.contain(
            "address=10%2520Park%2520Plaza,%2520Boston,%2520MA"
          );
          done();
        });
      });
    });

    describe("google session token", function() {
      it("gets set on focus if a token doesn't already exist", function() {
        expect(this.ac.sessionToken).to.equal(null);

        this.ac.onFocus();

        expect(this.ac.sessionToken).to.be.an.instanceOf(
          window.google.maps.places.AutocompleteSessionToken
        );
      });

      it("does not get reset on re-focus if a token already exists", function() {
        expect(this.ac.sessionToken).to.equal(null);

        this.ac.onFocus();

        expect(this.ac.sessionToken).to.be.an.instanceOf(
          window.google.maps.places.AutocompleteSessionToken
        );

        this.ac.sessionToken.id = "ORIGINAL_SESSION_TOKEN";
        this.ac.onFocus();

        expect(this.ac.sessionToken.id).to.equal("ORIGINAL_SESSION_TOKEN");
      });

      it("includes session token with location autocomplete queries", function(done) {
        window.Turbolinks = {
          visit: sinon.spy()
        };
        window.encodeURIComponent = params => {
          const forceString = params.toString();
          return forceString.replace(/\s/g, "%20").replace(/\&/g, "%26");
        };
        this.ac.init(this.client);
        this.ac.onFocus(); // initialize the session token
        this.ac.sessionToken.id = "SESSION_TOKEN";

        const result = this.ac._locationSource(
          "locations",
          this.autocompleteService
        )("10 park plaza", sinon.spy());

        Promise.resolve(result).then(() => {
          expect(this.autocompleteService.getPlacePredictions.called).to.be
            .true;

          const args = this.autocompleteService.getPlacePredictions.args[0][0];

          expect(args.sessionToken).to.be.an.instanceOf(
            window.google.maps.places.AutocompleteSessionToken
          );

          expect(args.sessionToken.id).to.equal("SESSION_TOKEN");

          done();
        });
      });
    });
  });
});

/* eslint-enable func-names */
/* eslint-enable prefer-arrow-callback */
/* eslint-enable no-unused-expressions */
