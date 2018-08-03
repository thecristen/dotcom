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

    this.markers = {
      from: null,
      to: null
    };

    this.bind();
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
    this.autocompletes = [this.toAutocomplete, this.fromAutocomplete];

    this.autocompletes.forEach(ac => {
      ac.renderHeaderTemplate = () => {};
      ac.renderFooterTemplate = this.renderFooterTemplate;
      ac.hasError = false;
      ac.onHitSelected = this.onHitSelected(
        ac,
        document.getElementById(ac._selectors.lat),
        document.getElementById(ac._selectors.lng)
      );
      ac._resetButton.addEventListener("click", () => { this.removeMarker(ac); });
      ac.showLocation = this.useMyLocation(ac);
    });

    this.toController.addWidget(this.toAutocomplete);
    this.fromController.addWidget(this.fromAutocomplete);
    document
      .getElementById("trip-plan-reverse-control")
      .addEventListener("click", this.reverseTrip);
    this.addExistingMarkers();
    this.setupFormValidation();
  }

  bind() {
    this.removeMarker = this.removeMarker.bind(this);
    this.reverseTrip = this.reverseTrip.bind(this);
    this.swapMarkers = this.swapMarkers.bind(this);
    this.resetResetButtons = this.resetResetButtons.bind(this);
    this.useMyLocation = this.useMyLocation.bind(this);
  }

  addExistingMarkers() {
    const fromAc = this.fromAutocomplete;
    const toAc = this.toAutocomplete;
    const $ = window.jQuery;
    const from = fromAc.getValue();
    const to = toAc.getValue();
    const fromLat = $("#from_latitude").val();
    const fromLng = $("#from_longitude").val();
    const toLat = $("#to_latitude").val();
    const toLng = $("#to_longitude").val();
    fromAc.setValue(from);
    toAc.setValue(to);
    if (fromLat && fromLng) {
      this.updateMarker(fromAc, fromLat, fromLng, from);
    }
    if (toLat && toLng) {
      this.updateMarker(toAc, toLat, toLng, to);
    }
    this.resetResetButtons();
  }

  setupFormValidation() {
    document.getElementById("trip-plan__submit").addEventListener("click", ev => {
      ev.preventDefault();
      const missingFrom = document.getElementById("from").value === "";
      const missingTo = document.getElementById("to").value === "";
      if (missingFrom || missingTo) {
        if (missingFrom) {
          this.toggleError(this.fromAutocomplete, true);
        }
        if (missingTo) {
          this.toggleError(this.toAutocomplete, true);
        }
      } else {
        document.getElementById("planner-form").submit();
      }
    });

    this.autocompletes.forEach(ac => {
      document.getElementById(ac._selectors.input).addEventListener("change", this.onInputChange(ac));
      document.getElementById(ac._selectors.input).addEventListener("input", this.onInputChange(ac));
    });

  }

  onInputChange(ac) {
    return (ev) => {
      this.toggleError(ac, false);
    }
  }

  toggleError(ac, hasError) {
    const required = document.getElementById(ac._selectors.required);
    const container = document.getElementById(ac._selectors.container);
    if (hasError) {
      container.classList.add("c-form__input-container--error");
      required.classList.remove("m-trip-plan__hidden");
      ac.hasError = true;
    } else {
      container.classList.remove("c-form__input-container--error");
      required.classList.add("m-trip-plan__hidden");
      ac.hasError = false;
    }
  }

  removeMarker(ac) {
    const $ = window.jQuery;
    const label = ac._input.getAttribute("data-label");
    const detail = { label };
    $(document).trigger("trip-plan:remove-marker", { detail });
  }

  updateMarker(ac, lat, lng, title) {
    const $ = window.jQuery;
    const label = ac._input.getAttribute("data-label");
    const detail = {
      latitude: lat,
      longitude: lng,
      label: label,
      title: title,
    }
    $(document).trigger("trip-plan:update-marker", { detail });
  }

  resetResetButtons() {
    const from = this.fromAutocomplete;
    const to = this.toAutocomplete;
    from.resetResetButton();
    to.resetResetButton();
  }

  swapMarkers() {
    const $ = window.jQuery;
    const from = this.fromAutocomplete;
    const to = this.toAutocomplete;

    const fromVal = from.getValue();
    const toVal = to.getValue();

    if (fromVal) {
      this.updateMarker(
        from,
        $("#from_latitude").val(),
        $("#from_longitude").val(),
        fromVal
      );
    } else {
      this.removeMarker(from);
    }

    if (toVal) {
      this.updateMarker(
        to,
        $("#to_latitude").val(),
        $("#to_longitude").val(),
        to
      );
    } else {
      this.removeMarker(to)
    }
  }

  useMyLocation(ac) {
    return (lat, lng, address) => {
      document.getElementById(ac._selectors.lat).value = lat;
      document.getElementById(ac._selectors.lng).value = lng;
      this.updateMarker(ac, lat, lng, address);
    }
  }

  onHitSelected(autocomplete, lat, lng) {
    return ({
      originalEvent: {
        _args: [hit, type]
      }
    }) => {
      if (type === "stops") {
        autocomplete.setValue(hit.stop.name);
        lat.value = hit._geoloc.lat;
        lng.value = hit._geoloc.lng;
        this.updateMarker(
          autocomplete,
          hit._geoloc.lat,
          hit._geoloc.lng,
          hit.stop.name
        );
      } else if (type === "locations") {
        GoogleMapsHelpers.lookupPlace(hit.place_id)
          .then(res => {
            autocomplete.setValue(hit.description);
            lat.value = res.geometry.location.lat();
            lng.value = res.geometry.location.lng();
            autocomplete._input.blur();
            this.updateMarker(
              autocomplete,
              res.geometry.location.lat(),
              res.geometry.location.lng(),
              hit.description
            );
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
    const fromAc = this.fromAutocomplete;
    const toAc = this.toAutocomplete;
    const fromError = fromAc.hasError;
    const toError = toAc.hasError;
    const $ = window.jQuery;
    const from = fromAc.getValue();
    const to = toAc.getValue();
    const fromLat = $("#from_latitude").val();
    const fromLng = $("#from_longitude").val();
    const toLat = $("#to_latitude").val();
    const toLng = $("#to_longitude").val();
    $("#from_latitude").val(toLat);
    $("#from_longitude").val(toLng);
    $("#to_latitude").val(fromLat);
    $("#to_longitude").val(fromLng);
    fromAc.setValue(to);
    toAc.setValue(from);
    this.swapMarkers();
    this.resetResetButtons();
    this.toggleError(toAc, fromError);
    this.toggleError(fromAc, toError);
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
    locationLoadingIndicator: "trip-plan__loading-indicator--to",
    required: "trip-plan__required--to"
  },
  from: {
    input: "from",
    lat: "from_latitude",
    lng: "from_longitude",
    resetButton: "trip-plan__reset--from",
    container: "trip-plan__container--from",
    locationLoadingIndicator: "trip-plan__loading-indicator--from",
    required: "trip-plan__required--from"
  },
  map: "trip-plan-map--initial"
};

TripPlannerLocControls.PARAMS = {
  stops: {
    hitsPerPage: 3,
    facets: ["*"],
    facetFilters: [[]]
  }
};
