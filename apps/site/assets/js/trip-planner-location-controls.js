import { doWhenGoogleMapsIsReady } from "./google-maps-loaded";
import * as GoogleMapsHelpers from "./google-maps-helpers";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo";

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => {
      new TripPlannerLocControls();
    });
  });
}

export class TripPlannerLocControls {
  constructor() {
    this.toInput = document.getElementById(
      TripPlannerLocControls.SELECTORS.to.input
    );
    this.fromInput = document.getElementById(
      TripPlannerLocControls.SELECTORS.from.input
    );
    this.toLat = document.getElementById(
      TripPlannerLocControls.SELECTORS.to.lat
    );
    this.toLng = document.getElementById(
      TripPlannerLocControls.SELECTORS.to.lng
    );
    this.fromLat = document.getElementById(
      TripPlannerLocControls.SELECTORS.from.lat
    );
    this.fromLng = document.getElementById(
      TripPlannerLocControls.SELECTORS.from.lng
    );
    this.controller = null;
    this.autocomplete = null;
    if (this.toInput && this.fromInput) {
      this.init();
    }
  }

  init() {
    this.toController = new Algolia(
      TripPlannerLocControls.INDICES.to,
      TripPlannerLocControls.PARAMS
    );
    this.fromController = new Algolia(
      TripPlannerLocControls.INDICES.from,
      TripPlannerLocControls.PARAMS
    );
    this.toAutocomplete = new AlgoliaAutocompleteWithGeo(
      TripPlannerLocControls.SELECTORS.to,
      Object.keys(TripPlannerLocControls.INDICES.to),
      {},
      { position: 1, hitLimit: 3 },
      this
    );

    this.fromAutocomplete = new AlgoliaAutocompleteWithGeo(
      TripPlannerLocControls.SELECTORS.from,
      Object.keys(TripPlannerLocControls.INDICES.from),
      {},
      { position: 1, hitLimit: 3 },
      this
    );
    [this.toAutocomplete, this.fromAutocomplete].forEach(ac => {
      ac.renderHeaderTemplate = () => {};
      ac.renderFooterTemplate = this.renderFooterTemplate;
      ac.onHitSelected = this.onHitSelected(
        ac,
        document.getElementById(ac._selectors.lat),
        document.getElementById(ac._selectors.lng)
      );
    });
    this.toController.addWidget(this.toAutocomplete);
    this.fromController.addWidget(this.fromAutocomplete);
    document
      .getElementById("trip-plan-reverse-control")
      .addEventListener("click", this.reverseTrip.bind(this));
  }

  onHitSelected(autocomplete, lat, lng) {
    return ({
      originalEvent: {
        _args: [hit, type]
      }
    }) => {
      if (type === "stops") {
        autocomplete.setValue(hit.stop.name);
        lat.value = hit.geoloc.lat;
        lng.value = hit.geoloc.lng;
      } else if (type === "locations") {
        GoogleMapsHelpers.lookupPlace(hit.place_id)
          .then(res => {
            autocomplete.setValue(hit.description);
            lat.value = res.geometry.location.lat();
            lng.value = res.geometry.location.lng();
            autocomplete.input.blur();
          })
          .catch(err => {
            // TODO: we should display an error here but NOT log to the console
          });
      }
    };
  }

  renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return AlgoliaResult.TEMPLATES.poweredByGoogleLogo.render({
        logo: document.getElementById("powered-by-google-logo").innerHTML
      });
    }
    return null;
  }

  reverseTrip() {
    const $ = window.jQuery;
    const from = $("#from").val();
    const to = $("#to").val();
    const fromLat = $("#from_latitude").val();
    const fromLng = $("#from_longitude").val();
    const toLat = $("#to_latitude").val();
    const toLng = $("#to_longitude").val();
    $("#from_latitude").val(toLat);
    $("#from_longitude").val(toLng);
    $("#to_latitude").val(fromLat);
    $("#to_longitude").val(fromLng);
    $("#from").val(to);
    $("#to").val(from);
  }
}

TripPlannerLocControls.INDICES = {
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
  }
};

TripPlannerLocControls.SELECTORS = {
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
};

TripPlannerLocControls.PARAMS = {
  stops: {
    hitsPerPage: 3,
    facets: ["*"],
    facetFilters: [[]]
  }
};
