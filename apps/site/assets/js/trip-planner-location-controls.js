import { doWhenGoogleMapsIsReady } from "./google-maps-loaded";
import * as GoogleMapsHelpers from "./google-maps-helpers";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo";
import { initMap } from "./google-map";
import * as Icons from "./icons";

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
    const maps = initMap(window.jQuery);
    if (maps) {
      const initialMap = maps[0];
      if (initialMap && initialMap.id === TripPlannerLocControls.SELECTORS.map) {
        this.map = initialMap.map;
      }
    } else {
      this.map = null;
    }
    this.defaultMapCenter = new google.maps.LatLng(42.360718, -71.0589099);

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

    const markerSvg = Icons.getSvgIcon("map-pin");
    const iconSize = 48;
    const markerImage = {
      url: `data:image/svg+xml;base64, ${window.btoa(markerSvg)}`,
      scaledSize: new google.maps.Size(iconSize, iconSize),
      origin: new google.maps.Point(0, 0),
      anchor: new google.maps.Point(iconSize / 2, iconSize),
      labelOrigin: new google.maps.Point(iconSize / 2, iconSize / 2 - 4)
    };
    const markerLabels = ["A", "B"].map(label => ({
      color: "#fff",
      fontSize: "22px",
      fontWeight: "bold",
      text: label,
      fontFamily: "Helvetica Neue, Helvetica, Arial"
    }));

    this.autocompletes.forEach(ac => {
      ac.renderHeaderTemplate = () => {};
      ac.renderFooterTemplate = this.renderFooterTemplate;
      ac.onHitSelected = this.onHitSelected(
        ac,
        document.getElementById(ac._selectors.lat),
        document.getElementById(ac._selectors.lng)
      );
      ac.marker = new google.maps.Marker({ icon: markerImage });
      ac._resetButton.addEventListener("click", () => { this.removeMarker(ac); });
      ac.showLocation = this.useMyLocation(ac);
    });

    this.fromAutocomplete.marker.setLabel(markerLabels[0]);
    this.toAutocomplete.marker.setLabel(markerLabels[1]);

    this.toController.addWidget(this.toAutocomplete);
    this.fromController.addWidget(this.fromAutocomplete);
    document
      .getElementById("trip-plan-reverse-control")
      .addEventListener("click", this.reverseTrip);
    window.addEventListener("resize", () => { this.fitBounds(); });
  }

  bind() {
    this.removeMarker = this.removeMarker.bind(this);
    this.reverseTrip = this.reverseTrip.bind(this);
    this.swapMarkers = this.swapMarkers.bind(this);
    this.resetResetButtons = this.resetResetButtons.bind(this);
    this.useMyLocation = this.useMyLocation.bind(this);
  }

  removeMarker(ac) {
    ac.marker.setPosition(null);
    ac.marker.setMap(null);
    this.fitBounds();
  }

  updateMarker(ac, lat, lng, title) {
    if (this.map) {
      const { marker } = ac;
      marker.setPosition(new google.maps.LatLng(lat, lng));
      marker.setTitle(title);
      marker.setMap(this.map);
    }
  }

  fitBounds() {
    if (this.map) {
      const bounds = new google.maps.LatLngBounds();
      let markerCount = 0;
      this.autocompletes.forEach(ac => {
        if (ac.marker.getPosition()) {
          bounds.extend(ac.marker.getPosition());
          markerCount += 1;
        }
      });
      if (markerCount === 0) {
        this.map.setCenter(this.defaultMapCenter);
        this.map.setZoom(14);
        return;
      }
      else if (markerCount == 1) {
        bounds.extend(this.defaultMapCenter);
      }
      this.map.fitBounds(bounds);
    }
  }

  resetResetButtons() {
    const from = this.fromAutocomplete;
    const to = this.toAutocomplete;
    from.resetResetButton();
    to.resetResetButton();
  }

  swapMarkers() {
    const from = this.fromAutocomplete;
    const to = this.toAutocomplete;
    const hasFrom = from && from.marker && from.marker.getPosition();
    const hasTo = to && to.marker && to.marker.getPosition();

    if (!hasFrom && !hasTo) {
      return;
    } else if (hasFrom && !hasTo) {
      this.updateMarker(
        to,
        from.marker.getPosition().lat(),
        from.marker.getPosition().lng(),
        from.marker.getTitle()
      );
      this.removeMarker(from);
    } else if (!hasFrom && hasTo) {
      this.updateMarker(
        from,
        to.marker.getPosition().lat(),
        to.marker.getPosition().lng(),
        to.marker.getTitle()
      );
      this.removeMarker(to);
    } else {
      const tmp = {
        lat: to.marker.getPosition().lat(),
        lng: to.marker.getPosition().lng(),
        title: to.marker.getTitle()
      }
      this.updateMarker(
        to,
        from.marker.getPosition().lat(),
        from.marker.getPosition().lng(),
        from.marker.getTitle()
      );
      this.updateMarker(
        from,
        tmp.lat,
        tmp.lng,
        tmp.title
      );
    }
    this.fitBounds();
  }

  useMyLocation(ac) {
    return (lat, lng, address) => {
      document.getElementById(ac._selectors.lat).value = lat;
      document.getElementById(ac._selectors.lng).value = lng;
      this.updateMarker(ac, lat, lng, address);
      this.fitBounds();
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
        this.fitBounds();
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
            this.fitBounds();
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
