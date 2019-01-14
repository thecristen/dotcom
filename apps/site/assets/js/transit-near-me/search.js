import { Algolia } from "../algolia-search";
import { AlgoliaAutocompleteWithGeo } from "../algolia-autocomplete-with-geo";

export class TransitNearMeSearch {
  constructor() {
    this.bind();
    this.controller = new Algolia({}, {});
    this.input = document.getElementById(TransitNearMeSearch.SELECTORS.input);
    this.latInput = document.getElementById(
      TransitNearMeSearch.SELECTORS.latitude
    );
    this.lngInput = document.getElementById(
      TransitNearMeSearch.SELECTORS.longitude
    );
    this.autocomplete = new AlgoliaAutocompleteWithGeo({
      id: "search-transit-near-me",
      selectors: TransitNearMeSearch.SELECTORS,
      indices: [],
      locationParams: TransitNearMeSearch.LOCATION_PARAMS,
      popular: [],
      parent: this
    });
    this.autocomplete.showLocation = this.showLocation;
    this.controller.addWidget(this.autocomplete);
  }

  bind() {
    this.showLocation = this.showLocation.bind(this);
  }

  showLocation(lat, lng, address) {
    this.input.value = address;

    this.latInput.value = lat;

    this.lngInput.value = lng;

    this.submit();
  }

  submit() {
    // this method gets stubbed in tests
    this.input.form.submit();
  }
}

TransitNearMeSearch.SELECTORS = {
  input: "search-transit-near-me__input",
  container: "search-transit-near-me__container",
  goBtn: "search-transit-near-me__input-go-btn",
  locationLoadingIndicator: "search-transit-near-me__loading-indicator",
  resetButton: "search-transit-near-me__reset",
  announcer: "search-transit-near-me__announcer",
  latitude: "search-transit-near-me__latitude",
  longitude: "search-transit-near-me__longitude"
};

TransitNearMeSearch.LOCATION_PARAMS = {
  hitsPerPage: 5
};
