import { AlgoliaAutocomplete } from "./algolia-autocomplete";
import * as GoogleMapsHelpers from './google-maps-helpers';
import * as Icons from './icons';
import geolocationPromise from "./geolocation-promise";
import * as AlgoliaResult from "./algolia-result";

export class AlgoliaAutocompleteWithGeo extends AlgoliaAutocomplete {
  constructor(id, selectors, indices, headers, locationParams, parent) {
    super(id, selectors, indices, headers, parent);
    this._loadingIndicator = document.getElementById(selectors.locationLoadingIndicator);
    this._locationParams = Object.assign(AlgoliaAutocompleteWithGeo.DEFAULT_LOCATION_PARAMS, locationParams);
    this._indices.splice(this._locationParams.position, 0, "locations");
  }

  init(client) {
    super.init(client);
    this._addUseMyLocation();
    this._addInputListeners();
  }

  bind() {
    super.bind();
    this.onInputFocused = this.onInputFocused.bind(this);
    this._closeUseMyLocation = this._closeUseMyLocation.bind(this);
  }

  onInputFocused() {
    if (this._input.value.length == 0) {
      this._useMyLocation.style.display = "block";

      const $ = window.jQuery;
      const borderWidth = parseInt($(`#${this._selectors.container}`).css("border-left-width"));
      this._useMyLocation.style.left = `${-borderWidth}px`;
      this._useMyLocation.style.top = `${this._searchContainer.offsetHeight - borderWidth}px`;
      this._useMyLocation.style.width = `${this._searchContainer.offsetWidth}px`;
    } else {
      this._closeUseMyLocation();
    }
  }

  _closeUseMyLocation() {
    this._useMyLocation.style.display = "none";
  }

  _addInputListeners() {
    this._input.removeEventListener("focusin", this.onInputFocused);
    this._input.addEventListener("focusin", this.onInputFocused);

    this._input.removeEventListener("input", this.onInputFocused);
    this._input.addEventListener("input", this.onInputFocused);

    this._input.removeEventListener("blur", this._closeUseMyLocation);
    this._input.addEventListener("blur", this._closeUseMyLocation);
  }

  _addUseMyLocation() {
    this._useMyLocation = document.createElement("div");
    this._useMyLocation.id = "use-my-location-container";
    this._useMyLocation.classList.add("c-search-bar__my-location-container");
    this._useMyLocation.classList.add("c-search-bar__-suggestion");
    this._useMyLocation.innerHTML = AlgoliaResult.renderResult({}, "usemylocation");
    this._useMyLocation.style.display = "none";
    this._input.parentNode.insertBefore(this._useMyLocation, this._input.nextSibling);
    this._useMyLocation.addEventListener("mousedown", this._useMyLocationSearch());
  }

  _datasetSource(index) {
    switch (index) {
      case "locations":
        return this._locationSource("locations");
      default:
        return super._datasetSource(index);
    }
  }

  _locationSource(index) {
    return (query, callback) => {
      const bounds = {
        west: 41.3193,
        north: -71.9380,
        east: 42.8266,
        south: -69.6189
      };
      return GoogleMapsHelpers.autocomplete(query, bounds, this._locationParams.hitLimit)
              .then(results => this._onResults(callback, index, results))
              .catch(err => console.error(err));
    }
  }

  onHitSelected(ev) {
    const hit = ev.originalEvent;
    const index = hit._args[1]
    switch (index) {
      case "locations":
        this._input.value = hit._args[0].description;
        this._doLocationSearch(hit._args[0].id);
        break;
      default:
        super.onHitSelected(ev);
    }
  }

  _useMyLocationSearch() {
    return () => {
      this._closeUseMyLocation();
      this._input.disabled = true;
      this.setValue("Getting your location...");
      this._loadingIndicator.style.visibility = "visible";
      geolocationPromise()
        .then(pos => this._doReverseGeocodeSearch(pos))
        .catch(err => console.error(err));
    }
  }

  _doLocationSearch(placeId) {
    return GoogleMapsHelpers.lookupPlace(placeId)
            .then(result => this._onLocationSearchResult(result))
            .catch(err => console.error("Error looking up place_id from Google Maps.", err));
  }

  _onLocationSearchResult(result) {
    return this.showLocation(result.geometry.location.lat(),
                              result.geometry.location.lng(),
                              result.formatted_address)
  }

  _doReverseGeocodeSearch({coords: {latitude, longitude}}) {
    return GoogleMapsHelpers.reverseGeocode(parseFloat(latitude), parseFloat(longitude))
             .then(result => this._onReverseGeocodeResults(result, latitude, longitude))
             .catch(err => console.error(err));
  }

  _onReverseGeocodeResults(result, latitude, longitude) {
    this._input.disabled = false;
    this.setValue(result);
    this._loadingIndicator.style.visibility = "hidden";
    this.showLocation(latitude, longitude, result);
  }

  showLocation(latitude, longitude, address) {
    this._parent.changeLocationHeader(address);
    return this._searchAlgoliaByGeo(latitude, longitude);
  }

  _geoSearch(placesResults) {
    const latitude = placesResults.geometry.location.lat();
    const longitude = placesResults.geometry.location.lng();
    this._searchAlgoliaByGeo(latitude, longitude);
    this._parent.changeLocationHeader(placesResults.formatted_address);
    return placesResults;
  }

  _searchAlgoliaByGeo(latitude, longitude) {
    this._client.reset();
    this._client.updateParamsByKey("stops", "aroundLatLng", `${latitude}, ${longitude}`);
    this._client.updateParamsByKey("stops", "hitsPerPage", 12);
    this._client.updateParamsByKey("stops", "getRankingInfo", true);
    return this._client.search({query: " "})
            .then(results => this._parent.onLocationResults(results))
            .catch(err => console.error(err));
  }

  _formatResult(hit) {
    hit.routes.map(route => {
      route.icon = Icons.getFeatureIcon(route.icon);
    });
    hit._rankingInfo.geoDistance = (hit._rankingInfo.geoDistance / METERS_PER_MILE).toFixed(1);
  }
}

AlgoliaAutocompleteWithGeo.DEFAULT_LOCATION_PARAMS = {
  position: 0,
  hitLimit: 5
}
