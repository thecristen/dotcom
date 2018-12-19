import { AlgoliaAutocomplete } from "./algolia-autocomplete";
import * as GoogleMapsHelpers from "./google-maps-helpers";
import * as QueryStringHelpers from "./query-string-helpers";
import geolocationPromise from "./geolocation-promise";
import * as AlgoliaResult from "./algolia-result";

export class AlgoliaAutocompleteWithGeo extends AlgoliaAutocomplete {
  constructor(id, selectors, indices, locationParams, popular, parent) {
    super(id, selectors, indices, parent);
    this.sessionToken = null;
    if (!this._parent.getParams) {
      this._parent.getParams = () => {
        return {};
      };
    }
    this._popular = popular;
    this._loadingIndicator = document.getElementById(
      selectors.locationLoadingIndicator
    );
    this.addUseMyLocationErrorEl();
    this._locationParams = Object.assign(
      AlgoliaAutocompleteWithGeo.DEFAULT_LOCATION_PARAMS,
      locationParams
    );
    this._indices.splice(this._locationParams.position, 0, "locations");
    this._indices.push("usemylocation");
    this._indices.push("popular");
  }

  bind() {
    super.bind();
    this.onFocus = this.onFocus.bind(this);
  }

  _addListeners() {
    super._addListeners();
    this._input.addEventListener("focus", this.onFocus);
  }

  onFocus() {
    if (!this.sessionToken) {
      this.sessionToken = new window.google.maps.places.AutocompleteSessionToken();
    }
  }

  resetSessionToken() {
    this.sessionToken = null;
  }

  addUseMyLocationErrorEl() {
    const container = document.getElementById(this._selectors.container);
    this.useMyLocationErrorEl = document.createElement("div");
    this.useMyLocationErrorEl.classList.add("u-error");
    this.useMyLocationErrorEl.style.display = "none";
    this.useMyLocationErrorEl.innerHTML = `${
      window.location.host
    } needs permission to use your location.
      Please update your browser's settings or refresh the page and try again.`;
    container.parentNode.appendChild(this.useMyLocationErrorEl);
  }

  _datasetSource(index) {
    switch (index) {
      case "locations":
        return this._locationSource("locations");
      case "usemylocation":
        return this._useMyLocationSource();
      case "popular":
        return this._popularSource();
      default:
        return super._datasetSource(index);
    }
  }

  _locationSource(index, service) {
    // service can be injected in tests
    return (input, callback) => {
      const searchBounds = {
        west: 41.3193,
        north: -71.938,
        east: 42.8266,
        south: -69.6189
      };
      return GoogleMapsHelpers.autocomplete({
        input,
        searchBounds,
        service,
        sessionToken: this.sessionToken,
        hitLimit: this._locationParams.hitLimit
      })
        .then(results => this._onResults(callback, index, results))
        .catch(err => console.error(err));
    };
  }

  _popularSource() {
    return (query, callback) => {
      const results = { popular: { hits: this._popular } };
      return this._onResults(callback, "popular", results);
    };
  }

  _useMyLocationSource() {
    return (query, callback) => {
      const results = { usemylocation: { hits: [{}] } };
      return this._onResults(callback, "usemylocation", results);
    };
  }

  minLength(index) {
    switch (index) {
      case "usemylocation":
      case "popular":
        return 0;
      default:
        return 1;
    }
  }

  maxLength(index) {
    switch (index) {
      case "usemylocation":
      case "popular":
        return 0;
      default:
        return null;
    }
  }

  onHitSelected(ev, placesService) {
    // placesService can be injected in tests
    const hit = ev.originalEvent;
    const index = hit._args[1];
    switch (index) {
      case "locations":
        this._input.value = hit._args[0].description;
        this._doLocationSearch(hit._args[0].id, placesService);
        break;
      case "usemylocation":
        this.useMyLocationSearch();
        break;
      default:
        super.onHitSelected(ev);
    }
  }

  useMyLocationSearch() {
    this.useMyLocationErrorEl.style.display = "none";
    this._input.disabled = true;
    this.setValue("Getting your location...");
    this._loadingIndicator.style.visibility = "visible";
    return geolocationPromise()
      .then(pos => this.onUseMyLocationResults(pos))
      .catch(err => this.onGeolocationError(err));
  }

  onGeolocationError(err) {
    this._input.disabled = false;
    this.setValue("");
    this._loadingIndicator.style.visibility = "hidden";
    if (err.code && err.code === 1) {
      this.useMyLocationErrorEl.style.display = "block";
    }
  }

  _doLocationSearch(placeId, service) {
    return GoogleMapsHelpers.lookupPlace(placeId, this.sessionToken, service)
      .then(result => this._onLocationSearchResult(result))
      .catch(err =>
        console.error("Error looking up place_id from Google Maps.", err)
      );
  }

  _onLocationSearchResult(result) {
    this.resetSessionToken();
    return this.showLocation(
      result.geometry.location.lat(),
      result.geometry.location.lng(),
      result.formatted_address
    );
  }

  onUseMyLocationResults({ coords: { latitude, longitude } }) {
    return GoogleMapsHelpers.reverseGeocode(
      parseFloat(latitude),
      parseFloat(longitude)
    )
      .then(result => this.onReverseGeocodeResults(result, latitude, longitude))
      .catch(err => console.error(err));
  }

  onReverseGeocodeResults(result, latitude, longitude) {
    this._input.disabled = false;
    this.setValue(result);
    this._loadingIndicator.style.visibility = "hidden";
    this.showLocation(latitude, longitude, result);
  }

  showLocation(latitude, longitude, address) {
    const params = this._parent.getParams();
    params.latitude = latitude;
    params.longitude = longitude;
    params.address = address;
    window.Turbolinks.visit(
      "/transit-near-me" + QueryStringHelpers.parseParams(params)
    );
  }
}

AlgoliaAutocompleteWithGeo.DEFAULT_LOCATION_PARAMS = {
  position: 0,
  hitLimit: 5
};
