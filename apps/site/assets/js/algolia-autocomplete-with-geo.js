import { AlgoliaAutocomplete } from "./algolia-autocomplete";
import * as GoogleMapsHelpers from './google-maps-helpers';
import geolocationPromise from "./geolocation-promise";

export class AlgoliaAutocompleteWithGeo extends AlgoliaAutocomplete {
  constructor(selectors, indices, parent) {
    super(selectors, indices);
    this._loadingIndicator = document.getElementById(selectors.locationLoadingIndicator);
    this._parent = parent;
    this._indices.unshift("usemylocation");
    this._indices.push("locations");
  }

  _datasetSource(index) {
    switch (index) {
      case "usemylocation":
        return this._emptySearchSource();
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
      return GoogleMapsHelpers.autocomplete(query, bounds)
              .then(results => this._onResults(callback, index, results))
              .catch(err => console.error(err));
    }
  }

  _hitsPerPage(index) {
    return index == "usemylocation" ? 0 : super._hitsPerPage(index);
  }

  onHitSelected(hit) {
    const index = hit._args[1]
    switch (index) {
      case "usemylocation":
        this._useMyLocationSearch();
        break;
      case "locations":
        this._doLocationSearch(hit._args[0].id);
        break;
      default:
        super.onHitSelected(hit);
    }
  }

  _useMyLocationSearch() {
    this._input.disabled = true;
    this._input.value = "Getting your location...";
    this._loadingIndicator.style.visibility = "visible";
    geolocationPromise()
      .then(pos => this._doReverseGeocodeSearch(pos))
      .catch(err => console.error(err));
  }

  _doLocationSearch(placeId) {
    return GoogleMapsHelpers.lookupPlace(placeId)
            .then(result => this._onLocationSearchResult(result))
            .catch(err => console.error("Error looking up place_id from Google Maps.", err));
  }

  _onLocationSearchResult(result) {
    return this._showLocation(result.geometry.location.lat(),
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
    this._input.value = result;
    document.getElementById("stop-search__loading-indicator").style.visibility = "hidden";
    this._showLocation(latitude, longitude, result);
  }

  _showLocation(latitude, longitude, address) {
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
    this._client.resetSearch();
    this._client.updateParamsByKey("stops", "aroundLatLng", `${latitude}, ${longitude}`);
    this._client.updateParamsByKey("stops", "hitsPerPage", 12);
    this._client.updateParamsByKey("stops", "getRankingInfo", true);
    return this._client.search(" ")
            .then(results => this._parent.onLocationResults(results))
            .catch(err => console.error(err));
  }

  _getFeatureIcon(feature) {
    return document.getElementById(`icon-feature-${feature}`).innerHTML;
  }

  _formatResult(hit) {
    hit.routes.map(route => {
      route.icon = this._getFeatureIcon(route.icon);
    });
    hit._rankingInfo.geoDistance = (hit._rankingInfo.geoDistance / METERS_PER_MILE).toFixed(1);
  }
}
