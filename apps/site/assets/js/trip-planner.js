import { doWhenGoogleMapsIsReady} from './google-maps-loaded';
import * as GoogleMapsHelpers from "./google-maps-helpers";
import hogan from "hogan.js";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo"

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => { new TripPlanner(); })
  });
}

export class TripPlanner {
  constructor() {
    this._toInput = document.getElementById(TripPlanner.SELECTORS.to.input);
    this._fromInput = document.getElementById(TripPlanner.SELECTORS.from.input);
    this._toLat = document.getElementById(TripPlanner.SELECTORS.to.lat);
    this._toLng = document.getElementById(TripPlanner.SELECTORS.to.lng);
    this._fromLat = document.getElementById(TripPlanner.SELECTORS.from.lat);
    this._fromLng = document.getElementById(TripPlanner.SELECTORS.from.lng);
    this._controller = null;
    this._autocomplete = null;
    this._bind();
    if (this._toInput && this._fromInput) {
      this.init();
    }
  }

  init() {
    this._toController = new Algolia(TripPlanner.INDICES.to, TripPlanner.PARAMS);
    this._fromController = new Algolia(TripPlanner.INDICES.from, TripPlanner.PARAMS);
    this._toAutocomplete = new AlgoliaAutocompleteWithGeo(TripPlanner.SELECTORS.to,
                                                        Object.keys(TripPlanner.INDICES.to),
                                                        {},
                                                        {position: 1, hitLimit: 3},
                                                        this);

    this._fromAutocomplete = new AlgoliaAutocompleteWithGeo(TripPlanner.SELECTORS.from,
                                                            Object.keys(TripPlanner.INDICES.from),
                                                            {},
                                                            {position: 1, hitLimit: 3},
                                                            this);
    [this._toAutocomplete, this._fromAutocomplete].forEach(ac => {
      ac.renderHeaderTemplate = () => {};
      ac.renderFooterTemplate = this._renderFooterTemplate;
      ac.onHitSelected = this._onHitSelected(ac,
                                             document.getElementById(ac._selectors.lat),
                                             document.getElementById(ac._selectors.lng));
    });
    this._toController.addWidget(this._toAutocomplete);
    this._fromController.addWidget(this._fromAutocomplete);
  }

  _bind() {
    this._renderFooterTemplate = this._renderFooterTemplate.bind(this);
  }

  _onHitSelected(autocomplete, lat, lng) {
    return ({originalEvent: {_args: [hit, type]}}) => {
      if (type == "stops") {
        autocomplete.setValue(hit.stop.name);
        lat.value = hit._geoloc.lat;
        lng.value = hit._geoloc.lng;
      }
      else if (type == "locations") {
        GoogleMapsHelpers.lookupPlace(hit.place_id)
          .then(res => {
            autocomplete.setValue(hit.description);
            lat.value = res.geometry.location.lat();
            lng.value = res.geometry.location.lng();
            autocomplete._input.blur();
          })
          .catch(err => { console.error(err); });
      }
    }
  }

  _renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return AlgoliaResult.TEMPLATES.poweredByGoogleLogo.render({
        logo: document.getElementById("powered-by-google-logo").innerHTML
      });
    }
    return null;
  }
}

TripPlanner.INDICES = {
  to: {
    stops: {
      indexName: "stops",
      query: ""
    }
  },
  from: {
    stops: {
      indexName: "stops",
      query: ""
    }
  },
}

TripPlanner.SELECTORS = {
  to: {
    input: "to",
    lat: "to_latitude",
    lng: "to_longitude",
    resetButton: "trip-plan__reset--to",
    container: "trip-plan__container--to",
    locationLoadingIndicator: "trip-plan__loading-indicator--to"
  },
  from: {
    input: "from",
    lat: "from_latitude",
    lng: "from_longitude",
    resetButton: "trip-plan__reset--from",
    container: "trip-plan__container--from",
    locationLoadingIndicator: "trip-plan__loading-indicator--from"
  }
}

TripPlanner.PARAMS = {
  stops: {
    hitsPerPage: 3,
    facets: ["*"],
    facetFilters: [[]]
  }
}
